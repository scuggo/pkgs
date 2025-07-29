{
  lib,
  newScope,
  callPackage,
  fetchFromGitHub,
  ...
}:
let
  src = fetchFromGitHub {
    owner = "qca";
    repo = "qca-swiss-army-knife";
    rev = "7c191e5530d32391105653b276ab587d2af9e02a";
    hash = "sha256-iE4lqyr3zmLcgFnsrDvQ/CKUV15ijqmIbUIs9sgMECg=";
  };
in
lib.makeScope newScope (self: {
  ath12k-tools = self.callPackage ./ath12k-tools.nix { inherit src; };
})
