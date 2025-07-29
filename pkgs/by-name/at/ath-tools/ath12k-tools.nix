{ src, python3, ... }:

python3.pkgs.buildPythonApplication rec {
  name = "ath12k-tools";
  pyproject = false;
  inherit src;
  sourceRoot = "source/tools/scripts/ath12k";
  installPhase = ''
    install -Dm755 "ath12k-bdencoder" "$out/bin/ath12k-bdencoder"
    install -Dm755 "ath12k-check" "$out/bin/ath12k-check"
    install -Dm755 "ath12k-fw-repo" "$out/bin/ath12k-fw-repo"
    install -Dm755 "ath12k-fwencoder" "$out/bin/ath12k-fwencoder"
  '';
}
