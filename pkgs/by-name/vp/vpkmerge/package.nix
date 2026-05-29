{
  lib,
  rustPlatform,
  callPackage,
  pkg-config,
  dbus,
  glib,
  cairo,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
}: let
  sources = callPackage ../../../../_sources/generated.nix {};
  inherit (sources.vpkmerge) src cargoLock;
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "vpkmerge";
    version = src.rev;
    src = src;
    cargoLock = sources.vpkmerge.cargoLock."Cargo.lock";

    nativeBuildInputs = [pkg-config dbus.dev];

    buildInputs = [dbus glib cairo gtk3 libsoup_3 webkitgtk_4_1];
  })
