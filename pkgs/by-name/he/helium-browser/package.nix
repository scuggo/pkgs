{
  stdenv,
  lib,
  makeWrapper,
  ed,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  adwaita-icon-theme,
  libva,
  pipewire,
  wayland,
  glib,
  libkrb5,
  xdg-utils,
  coreutils,
  gnugrep,
  callPackage,
  rustc,
}:
let
  upstream-info = (lib.importJSON ./info.json)."ungoogled-chromium";
  unwrapped = callPackage ./unwrapped.nix {
    inherit helium-patcher-unwrapped upstream-info;
    stdenv = rustc.llvmPackages.stdenv;
  };
  helium-patcher-unwrapped = callPackage ./helium-patcher.nix { };
  sandboxExecutableName = unwrapped.passthru.sandboxExecutableName;
in
stdenv.mkDerivation {
  pname = "helium-browser";
  inherit (unwrapped) version;

  nativeBuildInputs = [
    makeWrapper
    ed
  ];

  buildInputs = [
    # needed for GSETTINGS_SCHEMAS_PATH
    gsettings-desktop-schemas
    glib
    gtk3
    gtk4

    # needed for XDG_ICON_DIRS
    adwaita-icon-theme

    # Needed for kerberos at runtime
    libkrb5
  ];

  outputs = [
    "out"
    "sandbox"
  ];

  buildCommand =
    let
      browserBinary = "${unwrapped}/libexec/helium/helium";
      libPath = lib.makeLibraryPath [
        libva
        pipewire
        wayland
        gtk3
        gtk4
        libkrb5
      ];

    in
    ''
      mkdir -p "$out/bin"

      makeWrapper "${browserBinary}" "$out/bin/helium" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \

      ed -v -s "$out/bin/chromium" << EOF
      2i

      if [ -x "/run/wrappers/bin/${sandboxExecutableName}" ]
      then
        export CHROME_DEVEL_SANDBOX="/run/wrappers/bin/${sandboxExecutableName}"
      else
        export CHROME_DEVEL_SANDBOX="$sandbox/bin/${sandboxExecutableName}"
      fi

      # Make generated desktop shortcuts have a valid executable name.
      export CHROME_WRAPPER='chromium'

    ''
    + lib.optionalString (libPath != "") ''
      # To avoid loading .so files from cwd, LD_LIBRARY_PATH here must not
      # contain an empty section before or after a colon.
      export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH\''${LD_LIBRARY_PATH:+:}${libPath}"
    ''
    + ''

      # libredirect causes chromium to deadlock on startup
      export LD_PRELOAD="\$(echo -n "\$LD_PRELOAD" | ${coreutils}/bin/tr ':' '\n' | ${gnugrep}/bin/grep -v /lib/libredirect\\\\.so$ | ${coreutils}/bin/tr '\n' ':')"

      export XDG_DATA_DIRS=$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH\''${XDG_DATA_DIRS:+:}\$XDG_DATA_DIRS

    ''
    + lib.optionalString (!xdg-utils.meta.broken) ''
      # Mainly for xdg-open but also other xdg-* tools (this is only a fallback; \$PATH is suffixed so that other implementations can be used):
      export PATH="\$PATH\''${PATH:+:}${xdg-utils}/bin"
    ''
    + ''

      .
      w
      EOF

      ln -sv "${unwrapped.sandbox}" "$sandbox"

      ln -s "$out/bin/helium" "$out/bin/helium-browser"

      mkdir -p "$out/share"
      for f in '${unwrapped}'/share/*; do # hello emacs */
        ln -s -t "$out/share/" "$f"
      done
    '';

  inherit (unwrapped) packageName;
  meta = unwrapped.meta;
  passthru = {
    inherit (unwrapped) upstream-info;
    browser = unwrapped;
    inherit sandboxExecutableName;
    # TODO: enable and fix this script when bothered
    # updateScript = replaceVarsWith {
    #   src = ./update.mjs;
    #   replacements = {
    #     inherit nixpkgs;
    #   };
    #   dir = "bin";
    #   isExecutable = true;
    # };
  };
}
