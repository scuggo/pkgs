{
  callPackage,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  radare2,
}:

let
  sources = callPackage ../../../../_sources/generated.nix { };

  ghidra-native = fetchFromGitHub {
    owner = "radareorg";
    repo = "ghidra-native";
    rev = "0.6.4";
    hash = "sha256-DFvHM/erGE9wFjcB3Dlyhv4oebzXwe2yGG+GzLaY7hU=";
  };

  pugixml = fetchFromGitHub {
    owner = "zeux";
    repo = "pugixml";
    rev = "v1.15";
    hash = "sha256-t/57lg32KgKPc7qRGQtO/GOwHRqoj78lllSaE/A8Z9Q=";
  };
in
stdenv.mkDerivation {
  inherit (sources.radare2-ghidra) pname version src;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    radare2
  ];

  preConfigure = ''
    cp -r ${ghidra-native} subprojects/ghidra-native
    chmod -R u+w subprojects/ghidra-native

    # Overlay packagefiles (meson.build, etc.)
    cp -r subprojects/packagefiles/ghidra-native/* subprojects/ghidra-native/

    # Apply diff patches listed in the wrap file
    for p in subprojects/packagefiles/ghidra-native/patches/*.patch; do
      [ -f "$p" ] || continue
      echo "Applying patch: $p"
      patch -d subprojects/ghidra-native -p1 < "$p" || true
    done

    # Fix sleighc link: it needs ghidra_decompiler_static for symbols from pcodeinject.cc
    substituteInPlace subprojects/ghidra-native/meson.build \
      --replace-fail "link_with: slgh_static," \
                     "link_with: [slgh_static, ghidra_decompiler_static],"

    # Install into $out instead of radare2's store path
    substituteInPlace meson.build \
      --replace-fail "res = run_command(['radare2','-HR2_LIBR_PLUGINS'], capture:true, check:false)" \
                     "res = run_command(['false'], capture:true, check:false)"

    # pugixml subproject
    cp -r ${pugixml} subprojects/pugixml
    chmod -R u+w subprojects/pugixml
    cp -r subprojects/packagefiles/pugixml/* subprojects/pugixml/
  '';
}
