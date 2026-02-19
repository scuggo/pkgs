{
  lib,
  callPackage,
  stdenv,
  gnumake,
  dtc,
  glibc,
}:

let
  sources = callPackage ../../../../_sources/generated.nix { };
in
stdenv.mkDerivation {
  pname = "qebspil";
  version = "unstable-${sources.qebspil.date}";

  inherit (sources.qebspil) src;

  nativeBuildInputs = [
    gnumake
    dtc
  ];

  preBuild = ''
    # Create a symlink to glibc's elf.h for gnu-efi
    mkdir -p external/gnu-efi/inc/sys
    ln -sf ${glibc.dev}/include/elf.h external/gnu-efi/inc/sys/elf.h

    # Set up build environment
    export SRCDIR=$PWD
    export OUTDIR=$PWD/out
  '';

  makeFlags = [
    "QEBSPIL_ALWAYS_START=1"
    "CROSS_COMPILE="
    "ARCH=aarch64"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    # Install the EFI binary
    mkdir -p $out/share/efi
    cp out/qebspilaa64.efi $out/share/efi/

    # Also create a symlink in a more standard location
    mkdir -p $out/lib/systemd/boot/efi
    ln -s $out/share/efi/qebspilaa64.efi $out/lib/systemd/boot/efi/qebspilaa64.efi

    runHook postInstall
  '';

  meta = with lib; {
    description = "UEFI boot driver to start co-processors on Qualcomm platforms late during the boot process";
    homepage = "https://github.com/stephan-gh/qebspil";
    license = licenses.gpl2Only;
    platforms = [ "aarch64-linux" ];
    mainProgram = "qebspilaa64.efi";
  };
}
