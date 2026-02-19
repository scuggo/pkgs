{
  lib,
  callPackage,
  stdenv,
  ...
}:
let
  sources = callPackage ../../../../_sources/generated.nix { };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "base24-schemes";
  version = "unstable-${sources.base24-schemes.date}";

  inherit (sources.base24-schemes) src;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes/
    install base24/*.yaml $out/share/themes/

    runHook postInstall
  '';

  meta = with lib; {
    description = "All the color schemes for use in base24 packages";
    homepage = finalAttrs.src.meta.homepage;
    license = licenses.mit;
  };
})
