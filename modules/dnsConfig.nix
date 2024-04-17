{ utils, lib, ... }:
{
  options = {
    # todo
    # darwin = lib.mkOption {
    #   default = { };
    #   description = ''
    #   '';
    #   visible = false;
    #   type = import ./darwin.nix;
    # };
    nixosConfigurations = lib.mkOption {
      default = { };
      description = ''
        Takes in the equivalent of the self.nixosConfigurations flake attribute.
      '';
      visible = "shallow";
      type = lib.types.attrs;
      apply = x: if x != { } then utils.domains.getDomainsFromNixosConfigurations x else x;
    };
    extraConfig = lib.mkOption {
      apply = x: if x != { } then x.zones else x;
      default = { };
      description = ''
        Takes in the extraConfig module.
      '';
      visible = "shallow";
      type = lib.types.submodule (import ./extraConfig.nix);
    };
  };
}
