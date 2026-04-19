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
    sha256 = "0qadmn84sdqbqh3s837s0amdmln3akb1b01k8x5nha0lkw6a3jwc";
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
    				mkdir $out
        		cp -r ${src} $out/opt
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
