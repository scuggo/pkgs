{
  callPackage,
  stdenv,
  meson,
  ninja,
  pkg-config,
  radare2,
}:

let
  sources = callPackage ../../../../_sources/generated.nix { };
in
stdenv.mkDerivation {
  inherit (sources.radare2-mcp) pname version src;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    radare2
  ];

  mesonFlags = [
    "-Dr2_prefix=${radare2}"
  ];
}
