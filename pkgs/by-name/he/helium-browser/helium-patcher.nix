{
  stdenv,
  fetchFromGitHub,
  python3Packages,
  makeWrapper,
  patch,
}:

{
  rev,
  hash,
}:

stdenv.mkDerivation {
  pname = "helium-patcher";

  version = rev;

  src = fetchFromGitHub {
    owner = "imputnet";
    repo = "helium";
    inherit rev hash;
  };

  dontBuild = true;

  # patches = [ ./fix-scripts.patch ];

  buildInputs = [

    (python3Packages.python.withPackages (
      pythonPackages: with pythonPackages; [
        pillow
      ]
    ))

    patch
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  postPatch = ''
    sed -i '/chromium-widevine/d' patches/series
  '';

  installPhase = ''
    mkdir $out
    cp -R * $out/
    wrapProgram $out/utils/patches.py --add-flags "apply" --prefix PATH : "${patch}/bin"
    chmod +x $out/utils/name_substitution.py
    chmod +x $out/utils/helium_version.py
    chmod +x $out/utils/generate_resources.py
    chmod +x $out/utils/replace_resources.py
  '';
}
