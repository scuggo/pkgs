{
  lib,
  pkgs,
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
  gmp_override = pkgs.gmp.overrideAttrs (
    final: prev: {
      postInstall =
        (prev.postInstall or "")
        + "
				ls
				cd $out
				cd lib
				ls
			rm libgmp.so.10
			cp libgmp.so.10.5.0 libgmp.so.10
			cp libgmp.so.10.5.0 $out/libgmp.so.10
			";
    }
  );
  libs = [
    pkgs.stdenv.cc.cc.lib
    pkgs.libc
    pkgs.libcxx
    pkgs.gmp
    pkgs.libz
    pkgs.libgccjit
    # pkgs.zlib
    # pkgs.ncurses
  ];

  # we get Nixpkgs to create the library paths for us, so we don't have to wrangle them by hand
  libPath = pkgs.lib.makeLibraryPath libs;
in
stdenv.mkDerivation rec {
  pname = "hexagon-sdk";
  inherit version src;

  # dontUnpack = true;
  # dontBuild = true;

  nativeBuildInputs = [
  ];
  buildInputs = [ pkgs.patchelf ];
  runtimeDependencies = with pkgs; [ gmpxx ];

  buildPhase = ''
    runHook preBuild
    						# cp $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/lib/libLW.so.3 $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/bin/
    runHook postBuild
  '';

  installPhase = ''
                    runHook preInstall
                    mkdir $out
                    cp -r ${src} $out/opt
                    runHook postInstall

                    chmod +w $out/opt/ipc/fastrpc/qaic/bin/qaic
                		chmod +w $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/bin/hexagon-clang
                		chmod +w $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/bin/hexagon-link
                    patchelf $out/opt/ipc/fastrpc/qaic/bin/qaic --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} --set-rpath ${libPath}
                    patchelf $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/bin/hexagon-clang --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} --set-rpath ${libPath}
        						lib=${libPath}
        						lib=$lib:$out/opt/tools/HEXAGON_Tools/19.0.04/Tools/lib
    								echo $lib
                    patchelf $out/opt/tools/HEXAGON_Tools/19.0.04/Tools/bin/hexagon-link --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} --set-rpath $lib
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
