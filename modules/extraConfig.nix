{
  utils,
  lib,
  config,
  ...
}:
let
  isEmptyRecord =
    v:
    builtins.isAttrs v
    && v ? data
    && ((v.data or null) == null || (v.data or null) == [ null ])
    && (v.ttl or config.defaultTTL) == config.defaultTTL
    && (v.comment or null) == null
    && !(v.ttlAuto or false)
    && !(v.proxied or false);
in
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
        lib.filterAttrsRecursive (n: v: !(isEmptyRecord v)) (
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
