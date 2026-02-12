{
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  radare2,
}:

stdenv.mkDerivation rec {
  pname = "radare2-mcp";
  version = "1.5.4";

  src = fetchFromGitHub {
    owner = "radareorg";
    repo = "radare2-mcp";
    rev = version;
    hash = "sha256-YdniXuAiwR/oEFM14/LyxLL3HVI2K2/np8wQETkj01A=";
    # hash = "sha256-6Xy0oAR1DbdwxPgCQZVB3igSNUNbjFiNwUNTobRm070=";
  };

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
