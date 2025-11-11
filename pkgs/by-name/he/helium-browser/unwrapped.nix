{
  stdenv,
  upstream-info,
  chromium,
  fetchurl,
  go-crx3,
  overrideCC,
  pkgsBuildBuild,
  lib,
  electron-source,
  helium-patcher-unwrapped,
  fetchzip,

  proprietaryCodecs,
  cupsSupport,
  pulseSupport,
}:
(
  (chromium.passthru.mkDerivation.override (
    old:
    let
      warnObsoleteVersionConditional =
        min-version: result:
        let
          min-supported-version = (lib.head (lib.attrValues electron-source)).unwrapped.info.chromium.version;
          # Warning can be toggled by changing the value of enabled:
          enabled = false;
        in
        lib.warnIf (enabled && lib.versionAtLeast min-supported-version min-version)
          "chromium: min-supported-version ${min-supported-version} is newer than a conditional bounded at ${min-version}. You can safely delete it."
          result;
      chromiumVersionAtLeast =
        min-version:
        let
          result = lib.versionAtLeast upstream-info.version min-version;
        in
        warnObsoleteVersionConditional min-version result;
      versionRange =
        min-version: upto-version:
        let
          inherit (upstream-info) version;
          result = lib.versionAtLeast version min-version && lib.versionOlder version upto-version;
        in
        warnObsoleteVersionConditional upto-version result;

    in
    {
      inherit stdenv;
      ungoogled = true;
      ungoogled-chromium = helium-patcher-unwrapped;
      inherit
        upstream-info
        chromiumVersionAtLeast
        versionRange
        proprietaryCodecs
        cupsSupport
        pulseSupport
        ;

    }
  ))
  (
    base:
    let
      helium = helium-patcher-unwrapped {
        inherit (upstream-info.deps.ungoogled-patches) rev hash;
      };
      buildPlatformLlvmStdenv =
        let
          llvmPackages = pkgsBuildBuild.rustc.llvmPackages;
        in
        overrideCC llvmPackages.stdenv (
          llvmPackages.stdenv.cc.override {
            inherit (llvmPackages) bintools;
          }
        );

      ublock_src =
        let
          version = "1.67.0";
        in
        fetchurl {
          url = "https://github.com/imputnet/ublock-origin-crx/releases/download/${version}/uBlock0_${version}.crx";
          hash = "sha256-06NjhGEfV5Msg098vq6NdPXPrGNrqVUkz+nlLoFVAac=";

          recursiveHash = true;
          downloadToTemp = true;
          nativeBuildInputs = [
            go-crx3
          ];
          postFetch = ''
            mv "$downloadedFile" "$TMPDIR/uBlock0_${version}.crx"
            crx3 unpack "$TMPDIR/uBlock0_${version}.crx"
            mv "uBlock0_${version}" "$out"
          '';
        };
      helium-onboarding =
        let
          version = "202511061712";
        in
        fetchzip {
          url = "https://github.com/imputnet/helium-onboarding/releases/download/${version}/helium-onboarding-${version}.tar.gz";
          hash = "sha256-wsEFW9Psj4xTFUwgWC12aLErp/QKDIhcRkcw9WZms8Q=";
          stripRoot = false;
        };
      search-engine-data = fetchzip {
        url = "https://gist.githubusercontent.com/wukko/2a591364dda346e10219e4adabd568b1/raw/e75ae3c4a1ce940ef7627916a48bc40882d24d40/nonfree-search-engines-data.tar.gz";
        hash = "sha256-G83WwfoNmzI0ib9SRfjoDEoULnwgOTMQurlr1fKIpoo=";
        stripRoot = false;
      };

    in
    rec {
      inherit stdenv;
      pname = "helium-browser-unwrapped";
      version = "${upstream-info.deps.ungoogled-patches.rev}-${upstream-info.version}";
      depsBuildBuild = lib.filter (
        d: d != buildPlatformLlvmStdenv && d != buildPlatformLlvmStdenv.cc
      ) base.depsBuildBuild;
      # skip chromium-126-llvm-17.patch
      patches = lib.filter (
        p:
        let
          name = (builtins.baseNameOf p);
        in
        !builtins.elem name [
          "chromium-126-llvm-17.patch"
          "x5k78i7w4zics8v9b9azy4k1g7c8586z-chromium-141-Revert-Remove-unnecessary-include-in-tree_scope.h.patch"
        ]
      ) base.patches;

      postUnpack = ''
        cp -r ${helium-onboarding}/ src/components/helium_onboarding
        chmod +rw -R src/components/helium_onboarding
        cp -r ${ublock_src}/ src/third_party/ublock
        chmod +rw -R src/third_party/ublock
        cp -r ${search-engine-data}/. src/third_party/search_engines_data/resources_internal
        chmod +rw -R src/third_party/search_engines_data/resources_internal
      '';
      postPatch = base.postPatch + ''
        "${helium}/utils/name_substitution.py" --sub -t .
        "${helium}/utils/helium_version.py" --tree "${helium}" --chromium-tree .
        cp --no-preserve=mode,ownership -r "${helium}/resources" "$TMPDIR/helium-resources"
        "${helium}/utils/generate_resources.py" "${helium}/resources/generate_resources.txt" "$TMPDIR/helium-resources"
        "${helium}/utils/replace_resources.py" "${helium}/resources/helium_resources.txt" "$TMPDIR/helium-resources" .
      '';
      name = "helium-browser";
      packageName = "helium";
      buildTargets = [
        "run_mksnapshot_default"
        "chrome_sandbox"
        "chrome"
      ];

      outputs = [
        "out"
        "sandbox"
      ];

      sandboxExecutableName = "__chromium-suid-sandbox";

      installPhase = ''
        mkdir -p "$libExecPath"
        cp -v "$buildPath/"*.so "$buildPath/"*.pak "$buildPath/"*.bin "$libExecPath/"
        cp -v "$buildPath/libvulkan.so.1" "$libExecPath/"
        cp -v "$buildPath/vk_swiftshader_icd.json" "$libExecPath/"
        cp -v "$buildPath/icudtl.dat" "$libExecPath/"
        cp -vLR "$buildPath/locales" "$buildPath/resources" "$libExecPath/"
        cp -v "$buildPath/chrome_crashpad_handler" "$libExecPath/"
        cp -v "$buildPath/chrome" "$libExecPath/$packageName"

        # Swiftshader
        # See https://stackoverflow.com/a/4264351/263061 for the find invocation.
        if [ -n "$(find "$buildPath/swiftshader/" -maxdepth 1 -name '*.so' -print -quit)" ]; then
          echo "Swiftshader files found; installing"
          mkdir -p "$libExecPath/swiftshader"
          cp -v "$buildPath/swiftshader/"*.so "$libExecPath/swiftshader/"
        else
          echo "Swiftshader files not found"
        fi

        mkdir -p "$sandbox/bin"
        cp -v "$buildPath/chrome_sandbox" "$sandbox/bin/${sandboxExecutableName}"

        mkdir -vp "$out/share/man/man1"
        cp -v "$buildPath/chrome.1" "$out/share/man/man1/$packageName.1"

        for icon_file in chrome/app/theme/chromium/product_logo_*[0-9].png; do
          num_and_suffix="''${icon_file##*logo_}"
          icon_size="''${num_and_suffix%.*}"
          expr "$icon_size" : "^[0-9][0-9]*$" || continue
          logo_output_prefix="$out/share/icons/hicolor"
          logo_output_path="$logo_output_prefix/''${icon_size}x''${icon_size}/apps"
          mkdir -vp "$logo_output_path"
          cp -v "$icon_file" "$logo_output_path/$packageName.png"
        done

        # Install Desktop Entry
        install -D chrome/installer/linux/common/desktop.template \
          $out/share/applications/helium-browser.desktop

        substituteInPlace $out/share/applications/helium-browser.desktop \
          --replace "@@MENUNAME@@" "Helium" \
          --replace "@@PACKAGE@@" "helium" \
          --replace "Exec=/usr/bin/@@USR_BIN_SYMLINK_NAME@@" "Exec=helium"

        # Append more mime types to the end
        sed -i '/^MimeType=/ s,$,x-scheme-handler/webcal;x-scheme-handler/mailto;x-scheme-handler/about;x-scheme-handler/unknown,' \
          $out/share/applications/helium-browser.desktop

        # See https://github.com/NixOS/nixpkgs/issues/12433
        sed -i \
          -e '/\[Desktop Entry\]/a\' \
          -e 'StartupWMClass=helium-browser' \
          $out/share/applications/helium-browser.desktop
      '';

      passthru = {
        inherit sandboxExecutableName;
      };

      requiredSystemFeatures = [ "big-parallel" ];

    }
  )
)
