{
  lib,
  stdenvNoCC,
  stdenv,
  p7zip,
  curl,
  jq,
  cacert,
  nixpkgs,
}:

let
  version = "v6.4.0.2";
  src = fetchTarball {
    url = "https://github.com/snapdragon-toolchain/hexagon-sdk/releases/download/v6.4.0.2/hexagon-sdk-v6.4.0.2-amd64-lnx.tar.xz";
    sha256 = "b4a57a774795cf12da19a777a5d306e970905bf9758a4c4765e5e4593428ae0b";
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
    license = lib.licenses.proprietary;
    platforms = [
      "x86_64-linux"
    ];
  };
}
