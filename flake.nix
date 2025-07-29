{
  description = "Scuggo Pkgs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:

    {
      overlays.default =
        final: prev: (import "${nixpkgs}/pkgs/top-level/by-name-overlay.nix" ./pkgs/by-name) final prev;
    }
    //
      flake-utils.lib.eachSystem
        [
          "x86_64-linux"
          "aarch64-linux"
        ]
        (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
            };
            inherit (pkgs) lib;
            scope = lib.makeScope pkgs.newScope (final: self.overlays.default (pkgs // final) pkgs);
            recursePackage =
              name: pkg:
              let
                isDrv = lib.isDerivation pkg;
                isAttrs = lib.isAttrs pkg;
              in
              if isDrv then
                [
                  (lib.nameValuePair name pkg)
                ]
              else if isAttrs then
                lib.mapAttrsToList (nameNew: subPkg: recursePackage "${name}-${nameNew}" subPkg) pkg
              else
                [ ];
            flatPackages = builtins.listToAttrs (
              lib.lists.flatten (lib.mapAttrsToList (name: pkg: recursePackage name pkg) scope)
            );
            workingPackages = lib.filterAttrs (_: pkg: !pkg.meta.broken) self.packages.${system};
          in
          {
            inherit flatPackages;
            inherit pkgs;
            packages = lib.filterAttrs (
              _: pkg: lib.isDerivation pkg && (lib.meta.availableOn pkgs.stdenv.hostPlatform pkg)
            ) scope;
            checks = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") workingPackages;
          }
        );
}
