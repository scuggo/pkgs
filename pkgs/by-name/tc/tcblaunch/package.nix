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
  version = "22621.6060";
  # Fixed-Output Derivation to fetch winre.wim from Microsoft CDN via UUPDump API
  winre-wim = stdenvNoCC.mkDerivation {
    pname = "winre-wim";
    inherit version;
    nativeBuildInputs = [
      curl
      jq
      cacert
    ];

    UUP_ID = "b90029a9-23b4-4558-9687-2142f79e5ae2";

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      echo "Querying UUPDump API for winre.wim..."
      WINRE_URL=$(curl -s "https://api.uupdump.net/get.php?id=$UUP_ID" | jq -r '.response.files["winre.wim"].url')

      if [[ -z "$WINRE_URL" || "$WINRE_URL" == "null" ]]; then
        echo "ERROR: Failed to get winre.wim URL from UUPDump API"
        exit 1
      fi

      echo "Downloading winre.wim from: $WINRE_URL"
      curl -L -o winre.wim "$WINRE_URL"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp winre.wim "$out"
      runHook postInstall
    '';

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-jEBM0ZXEqe7HEjbpQdWNumWH5/KmCuGnIcIlFGN3W6g=";

    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  };
in
stdenv.mkDerivation rec {
  pname = "tcblaunch";
  inherit version;
  src = winre-wim;

  nativeBuildInputs = [ p7zip ];

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    echo "Extracting tcblaunch.exe from winre.wim..."
    mkdir -p extracted
    7z e "$src" -oextracted 'Windows/System32/tcblaunch.exe' -y
    if [[ ! -f "extracted/tcblaunch.exe" ]]; then
      echo "ERROR: tcblaunch.exe was not extracted"
      exit 1
    fi
    ls -lh extracted/tcblaunch.exe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/tcblaunch"
    cp extracted/tcblaunch.exe "$out/share/tcblaunch/tcblaunch.exe"
    chmod 644 "$out/share/tcblaunch/tcblaunch.exe"
    runHook postInstall
  '';

  meta = {
    description = "Microsoft tcblaunch.exe for Qualcomm Secure Launch (required by slbounce)";
    homepage = "https://github.com/TravMurav/slbounce";
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
