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
  breakpointHook,
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
  # cargoHash = "sha256-qh8mHDgIwh20I8P8rx25CZIVB8X4ZtY7/lyGQ3xy/7k=";

  # Assuming our app's frontend uses `npm` as a package manager
  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    src = "${finalAttrs.src}/src-vue";
    hash = "sha256-QhUPkCBK1kcAF7gByFxlg8Ca9PLF3evCl0QYEPP/Q2c=";
  };

  nativeBuildInputs = [
    # Pull in our main hook
    cargo-tauri.hook

    # Setup npm
    nodejs
    npmHooks.npmConfigHook

    # Make sure we can find our libraries
    pkg-config

    jq
    moreutils
    breakpointHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking # Most Tauri apps need networking
    openssl
    webkitgtk_4_1
  ];

  # Set our Tauri source directory
  cargoRoot = "src-tauri";
  npmRoot = "src-vue";
  # And make sure we build there too
  buildAndTestSubdir = finalAttrs.cargoRoot;

  meta = {
    description = "FlightCore A Northstar installer, updater, and mod-manager";

  };
})
