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
    }@inputs:

    {
      overlays.default =
        final: prev: ((import "${nixpkgs}/pkgs/top-level/by-name-overlay.nix" ./pkgs/by-name) final prev);
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
                isSameSystem = lib.meta.availableOn pkgs.stdenv.hostPlatform pkg;
              in
              if !isSameSystem then
                [ ]
              else if isDrv then
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
            workingPackages = lib.filterAttrs (_: pkg: !pkg.meta.broken) flatPackages;
            # Disable for now
            # recursePackageSets =
            #   pkg:
            #   let
            #     isDrv = lib.isDerivation pkg;
            #     isAttrs = lib.isAttrs pkg;
            #     isSameSystem = lib.meta.availableOn pkgs.stdenv.hostPlatform pkg;
            #   in
            #   if isDrv && isSameSystem then
            #     pkg
            #   else if isAttrs then
            #     lib.mapAttrs (_: subPkg: recursePackageSets subPkg) pkg
            #   else
            #     null;
            #
            # # Recursively filter out nulls and remove overrides (probably a btter way to do this but it works for now)
            # packageSets = lib.filterAttrsRecursive (k: v: v != null && k != "override") (
            #   lib.mapAttrs (name: pkg: recursePackageSets pkg) scope
            # );
          in
          {
            packages = flatPackages;
            checks = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") workingPackages;
          }
        );
}
