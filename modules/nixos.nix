{ utils }: { lib
           , pkgs
           , config
           , ...
             # , nixosSystem
           }:
let
  cfg = config.networking.domains;
  records = import ./records.nix { inherit lib utils cfg; };
in
{
  options = {
    networking.domains = with lib.types; {
      enable = lib.mkEnableOption "networking.domains";
      defaultTTL = import ./defaultTTL.nix { inherit lib; };
      baseDomains = lib.mkOption {
        default = { };
        description = lib.mdDoc ''
          Attribute set of domains and records for the subdomains to inherit.
        '';
        type = attrsOf (submodule {
          options = records.base;
        });
      };
      subDomains = lib.mkOption {
        description = lib.mdDoc ''
          Attribute set of subdomains that inherit values from there matching domain.
        '';
        default = { };
        apply = lib.filterAttrsRecursive (n: v:
          cfg.enable
          && v
          != {
            data = null;
            ttl = cfg.defaultTTL;
          }
          && v
          != {
            data = [ null ];
            ttl = cfg.defaultTTL;
          });
        type = attrsOf (submodule ({ name, ... }: {
          options = lib.mapAttrs (n: v: (v name)) records.sub;
        }));
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !((builtins.length (builtins.filter (i: i == null) (lib.mapAttrsToList (n: v: utils.domains.getMostSpecific n (lib.mapAttrsToList (i: o: i) cfg.baseDomains)) cfg.subDomains))) > 0);
        message = ''
          At least one of your subdomains doesn't have a matching basedomain
        '';
      }

      # To Do
      {
        assertion = true;
        message = ''
          If you set a CNAME no a or aaaa record can be set and CNAME subdomain can not be the zone apex
        '';
      }
      {
        assertion = true;
        message = ''
          Alais assertion, same as CNAME but a alias is allowed as zone apex
        '';
      }
      {
        assertion = true;
        message = ''
          If you need a soa please specify it in the dnsConfig extraConfig attribute and not in nixosConfigurations
        '';
      }
    ];
  };
}
