{
  lib,
  buildGoModule,
  callPackage,
}:
let
  sources = callPackage ../../../../_sources/generated.nix { };
in
buildGoModule (finalAttrs: {
  pname = "claude-sync";
  version = lib.removePrefix "v" sources.claude-sync.version;
  inherit (sources.claude-sync) src;

  vendorHash = "sha256-cHWP5m191QP4XxeOtgHaLsyavXWikUwViDivBMGP34M=";

  subPackages = [ "cmd/claude-sync" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  meta = {
    mainProgram = "claude-sync";
    platforms = lib.platforms.unix;
  };
})
