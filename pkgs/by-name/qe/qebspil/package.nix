{
  lib,
  stdenv,
  fetchFromGitHub,
  gnumake,
  dtc,
  glibc,
}:

stdenv.mkDerivation rec {
  pname = "qebspil";
  version = "unstable-2025-10-25";

  src = fetchFromGitHub {
    owner = "stephan-gh";
    repo = "qebspil";
    rev = "8e4d9e676a3b3afe136cda9b953a2139ff1a32d0";
    hash = "sha256-kWUXzeYWNxGgmjt/p9yozrWc5ouUs0XXBRfiFMlu+QQ=";
    fetchSubmodules = true;
  };

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
