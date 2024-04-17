{
  utils,
  lib,
  config,
  ...
}:
{
  options = {
    defaultTTL = import ./defaultTTL.nix { inherit lib; };
    zones = lib.mkOption {
      default = { };
      description = ''
        Takes in a attrset of domain apex and their entries.
      '';
      apply =
        x:
        lib.filterAttrsRecursive
          (
            n: v:
            v != {
              data = null;
              ttl = config.defaultTTL;
            }
            &&
              v != {
                data = [ null ];
                ttl = config.defaultTTL;
              }
          )
          (
            if x != { } then
              (lib.mapAttrs (
                zone: entries:
                lib.mapAttrs' (
                  name: value: lib.nameValuePair (if name != "" then "${name}.${zone}" else zone) value
                ) entries
              ) x)
            else
              x
          );
      type = lib.types.attrsOf (
        lib.types.attrsOf (
          lib.types.submodule {
            options =
              (import ./records.nix {
                inherit lib utils;
                cfg = {
                  inherit (config) defaultTTL;
                  baseDomains = [ "dummy.input.invalid" ];
                };
              }).base;
          }
        )
      );
    };
  };
}
