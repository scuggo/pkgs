{ ath-tools, linux-firmware }:
linux-firmware.overrideAttrs (final: {
  postInstall = ''
    mkdir temp
    cd temp || exit
    ${ath-tools.ath12k-tools}/bin/ath12k-bdencoder -e $out/lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin
    patch -p1 < ${./firmware.patch}
    ${ath-tools.ath12k-tools}/bin/ath12k-bdencoder -c board-2.json
    cp board-2.bin $out/lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin
  '';
})
