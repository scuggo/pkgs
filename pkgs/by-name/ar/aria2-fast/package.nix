{ aria2 }:
aria2.overrideAttrs (oldAttrs: rec {
  patches = oldAttrs.patches or [ ] ++ [ ./unlimited.patch ];
})
