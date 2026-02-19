{
  lib,
  newScope,
  callPackage,
  ...
}:
let
  sources = callPackage ../../../../_sources/generated.nix { };
  inherit (sources.ath-tools) src;
in
lib.makeScope newScope (self: {
  ath12k-tools = self.callPackage ./ath12k-tools.nix { inherit src; };
})
