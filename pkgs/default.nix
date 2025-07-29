prev: final:
builtins.listToAttrs (
  map (fn: {
    name = fn;
    value = prev.callPackage ./${fn} { };
  }) (builtins.filter (fn: fn != "default.nix") (builtins.attrNames (builtins.readDir ./.)))
)
