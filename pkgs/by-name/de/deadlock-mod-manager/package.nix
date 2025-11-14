{
  stdenv,
  rustPlatform,
  nodejs,
  pnpm,
  fetchFromGitHub,
  lib,
  pkg-config,
  moreutils,
  cargo-tauri,
  jq,
  glib-networking,
  openssl,
  webkitgtk_4_1,
  wrapGAppsHook4,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "deadlock-mod-manager";
  version = "0.10.1";
  VITE_API_URL = "https://api.deadlockmods.app";
  VITE_WEB_URL = "https://deadlockmods.app";
  src = fetchFromGitHub {
    owner = "deadlock-mod-manager";
    repo = "deadlock-mod-manager";
    rev = "v${finalAttrs.version}";
    hash = "sha256-/84P9ONG25Ia1BnRcbzQuJKt8HwstCzf0bkx1Xc9VgU=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    src = finalAttrs.src;
    sourceRoot = "${finalAttrs.src.name}/${finalAttrs.cargoRoot}";
    hash = "sha256-wVsr6GwCGuuveTDT6oS1keejx+y+oSuE6dGAjvNRrdE=";
  };

  postPatch = ''
    sed -i '/^[[:space:]]*app\.deep_link()\.register("deadlock-mod-manager")?;/d' ${finalAttrs.cargoRoot}/src-tauri/src/lib.rs
        # sed -i 's/log::LevelFilter::Info/log::LevelFilter::Trace/' ${finalAttrs.cargoRoot}/src-tauri/src/lib.rs
        sed -i '/\.manage(discord_rpc::DiscordState::new())/d' ${finalAttrs.cargoRoot}/src-tauri/src/lib.rs
        sed -i '/\.plugin(tauri_plugin_updater::Builder::new()\.build())/d' ${finalAttrs.cargoRoot}/src-tauri/src/lib.rs
        jq '.bundle.createUpdaterArtifacts = false | del(.plugins.updater)' ${finalAttrs.cargoRoot}/src-tauri/tauri.conf.json | sponge ${finalAttrs.cargoRoot}/src-tauri/tauri.conf.json
  '';

  nativeBuildInputs = [

    cargo-tauri.hook

    nodejs
    # npmHooks.npmConfigHook

    pkg-config

    jq
    moreutils
    nodejs
    pnpm.configHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking
    openssl
    webkitgtk_4_1
  ];

  # buildPhase = ''
  #   pnpm --filter desktop tauri build
  # '';

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "sha256-FwY7jN9m6xNSlwpCb1GY8Rqr9w/kJIj7uIauOXTm7O0=";
  };
  doCheck = false;
  cargoRoot = "apps/desktop";
  # npmRoot = "src-vue";

  buildAndTestSubdir = finalAttrs.cargoRoot;

})
