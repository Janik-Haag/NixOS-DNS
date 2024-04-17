# Debug just provides wrapper functions with a stable interface.
{ lib, utils }:
{
  /*
    Takes in one nixosConfiguration and returns a set of all the merged nixos-dns values.

    Type:
      utils.debug.host :: nixosConfiguration -> AttrSet
  */
  host =
    # The host you want to debug
    host: utils.domains.getDomainsFromNixosConfigurations { inherit host; };

  /*
    Function that returns the set of all the merged hosts and extraConfig

    Type:
      utils.debug.config :: (AttrSet of dnsConfig) -> AttrSet
  */
  config =
    # The dnsConfig module set
    dnsConfig: utils.domains.getDnsConfig dnsConfig;
}
