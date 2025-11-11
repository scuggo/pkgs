{
  lib,
  stdenv,
  rustPlatform,
  jq,
  moreutils,
  fetchNpmDeps,
  cargo-tauri,
  glib-networking,
  nodejs,
  npmHooks,
  openssl,
  pkg-config,
  webkitgtk_4_1,
  wrapGAppsHook4,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "flightcore";
  version = "3.2.0";
  src = fetchFromGitHub {
    owner = "R2NorthstarTools";
    repo = "FlightCore";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-MFnW9cXFzqmdtC31r8cRcihV3NjGAC6+2/DnNVMheCI=";
  };
  patches = [ ./cargo-lock.patch ];
  cargoDeps = rustPlatform.fetchCargoVendor {
    src = finalAttrs.src;
    sourceRoot = "${finalAttrs.src.name}/${finalAttrs.cargoRoot}";
    hash = "sha256-Jh0DAX4fGy2Z1+hpq+bkU/VYy2JAL2u+neUIsQ2QXBU=";
    patchFlags = "-p2";
    inherit (finalAttrs) patches;
  };
  postPatch = ''
    jq '.bundle.createUpdaterArtifacts = false' src-tauri/tauri.conf.json | sponge src-tauri/tauri.conf.json
  '';
  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    src = "${finalAttrs.src}/src-vue";
    hash = "sha256-QhUPkCBK1kcAF7gByFxlg8Ca9PLF3evCl0QYEPP/Q2c=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook

    nodejs
    npmHooks.npmConfigHook

    pkg-config

    jq
    moreutils
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking
    openssl
    webkitgtk_4_1
  ];

  cargoRoot = "src-tauri";
  npmRoot = "src-vue";

  buildAndTestSubdir = finalAttrs.cargoRoot;

  meta = {
    platforms = [ "x86_64-linux" ];
    description = "FlightCore A Northstar installer, updater, and mod-manager";
  };
})
