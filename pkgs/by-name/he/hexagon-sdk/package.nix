{
  lib,
  stdenvNoCC,
  stdenv,
  p7zip,
  curl,
  jq,
  cacert,
}:

let
  version = "v6.4.0.2";
  src = fetchTarball {
    url = "https://github.com/snapdragon-toolchain/hexagon-sdk/releases/download/v6.4.0.2/hexagon-sdk-v6.4.0.2-amd64-lnx.tar.xz";
    sha256 = "02xf50s5kr75cm3lr2kmz5dr0w790v9saxx737d15kwm8xvpm9dl";
  };
in
stdenv.mkDerivation rec {
  pname = "hexagon-sdk";
  inherit version src;

  dontUnpack = true;
  dontBuild = true;

  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall
    		cp -p ${src} $out/opt
        runHook postInstall
  '';

  meta = {
    description = "Hexagon SDK for working with the Qualcomm NPU/DSP";
    homepage = "https://github.com/snapdragon-toolchain/hexagon-sdk";
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
    ];
  };
}
