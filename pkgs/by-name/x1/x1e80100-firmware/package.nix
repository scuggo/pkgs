{
  msitools,
  tree,
  fetchurl,
  lib,
  stdenv,
  ...
}:

stdenv.mkDerivation (
  let
    fw_files = [
      "adsp_dtbs.elf"
      "adspr.jsn"
      "adsps.jsn"
      "adspua.jsn"
      "battmgr.jsn"
      "cdsp_dtbs.elf"
      "cdspr.jsn"
      "qcadsp8380.mbn"
      "qccdsp8380.mbn"
      "qcdxkmsuc8380.mbn"
      "bdwlan01.e0b"
    ];

  in

  rec {
    name = "x1e80100-firmware";
    version = "26100_25.101.12926.0";
    src = fetchurl {
      # https://www.microsoft.com/en-us/download/details.aspx?id=106120
      url = "https://download.microsoft.com/download/b7ca2c3f-d320-4795-be0f-529a0117abb4/SurfaceLaptop7_ARM_Win11_${version}.msi";
      hash = "sha256-4LVqkA4YwGrAh3gNSUQ5G2ahwBoj/5QvyFqvNgznvX4=";
    };
    nativeBuildInputs = [
      msitools
      tree
    ];
    unpackPhase = ''
      msiextract -C . "$src"
    '';
    buildPhase = ''
      mkdir -p "$out/lib/firmware/qcom/x1e80100/microsoft/Romulus"
      for file in ${lib.concatStringsSep " " fw_files}; do
          echo -e "\tSearching for $file..."
          fw_path=$(find . -type f -name "$file" -print | head -n 1)
          if [[ -n "$fw_path" ]]; then
              cp -v "$fw_path" "$out/lib/firmware/qcom/x1e80100/microsoft/Romulus/"
          else
              echo "Error: $file not found!"
              exit 1
          fi
      done
      cp "$out/lib/firmware/qcom/x1e80100/microsoft/Romulus/qcdxkmsuc8380.mbn" "$out/lib/firmware/qcom/x1e80100/microsoft/qcdxkmsuc8380.mbn"
    '';
    meta = {
      platforms = [ "aarch64-linux" ];
    };

  }
)
