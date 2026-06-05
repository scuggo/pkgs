{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  nodejs_22,
  pnpm,
  python3,
  gcc,
  gnumake,
  pkg-config,
  makeWrapper,
  electron_40,
  vpkmerge,
  sqlite,
  callPackage,
  makeDesktopItem,
  copyDesktopItems,
}: let
  sources = callPackage ../../../../_sources/generated.nix {};

  src = sources.grimoire.src;
  version = src.rev;

  # This would go into nvfetcher but it isnt versioned..
  grimoire-social-src = fetchFromGitHub {
    owner = "Slush97";
    repo = "grimoire-social";
    rev = "main";
    hash = "sha256-f+wUZOR7dqigxd/IZtay1BrLS5rcSnaDage3NXxqsPE=";
  };

  pnpmDeps = pnpm.fetchDeps {
    pname = "grimoire";
    inherit version src;
    fetcherVersion = 3;
    hash = "sha256-aSjELhEyEbQ7qT8fI5VfIDOHrsgHHL18Dsphm6sA8J4=";
  };

  desktopItem = makeDesktopItem {
    name = "grimoire";
    exec = "/bin/grimoire %u";
    desktopName = "Grimoire";
    categories = ["Utility"];
    mimeTypes = ["x-scheme-handler/grimoire"];
  };
in
  stdenv.mkDerivation {
    pname = "grimoire";
    inherit version src;

    nativeBuildInputs = [
      nodejs_22
      pnpm
      pnpm.configHook
      python3
      gcc
      gnumake
      pkg-config
      makeWrapper
      electron_40
      copyDesktopItems
    ];

    desktopItems = [desktopItem];

    buildInputs = [
      sqlite
    ];

    inherit pnpmDeps;

    env.GRIMOIRE_SOCIAL_BASE_URL = "https://grimoire-social.slusheliott.workers.dev";

    postPatch = ''
      cp -r ${grimoire-social-src} ../grimoire-social
      chmod -R u+w ../grimoire-social

      mkdir -p resources/vpkmerge
      cp ${vpkmerge}/bin/vpkmerge resources/vpkmerge/vpkmerge-linux-x86_64
      chmod +x resources/vpkmerge/vpkmerge-linux-x86_64
    '';

    buildPhase = ''
      runHook preBuild

      mkdir -p ../grimoire-social/node_modules
      ln -sfn "$(realpath node_modules/zod)" ../grimoire-social/node_modules/zod

      (
        cd node_modules/better-sqlite3
        HOME="$TMPDIR" node \
          "${nodejs_22}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js" \
          rebuild \
          --nodedir="${electron_40.headers}"
      )

      pnpm exec electron-vite build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/grimoire
      cp -r dist $out/lib/grimoire/dist

      mkdir -p $out/lib/grimoire/resources
      cp -r resources/vpkmerge $out/lib/grimoire/resources/vpkmerge
      echo '{"name":"grimoire","version":"${version}","main":"dist/main/index.js"}' \
      > $out/lib/grimoire/package.json

      cp -r node_modules $out/lib/grimoire/node_modules

      rm -rf "$out/lib/grimoire/node_modules/@grimoire"

      find "$out/lib/grimoire/node_modules" -type l | while read -r link; do
      [ -e "$link" ] || rm -f "$link"
      done

      mkdir -p $out/bin
      makeWrapper ${electron_40}/bin/electron $out/bin/grimoire \
      --add-flags "$out/lib/grimoire" \
      --set ELECTRON_RESOURCES_PATH "$out/lib/grimoire" \
      --set NODE_ENV production

      runHook postInstall
    '';

    meta = {
      description = "Grimoire — Electron-based mod manager";
      platforms = ["x86_64-linux"];
    };
  }
