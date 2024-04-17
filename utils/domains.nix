# Functions to work with domains

{ lib, utils }:
{
  /*
    Convert a string like "example.org"
    to a list like `[ "example" "org" ]`

    Type:
      utils.domains.getParts :: String -> [ String ]
  */
  getParts =
    # String of a domain
    domains:
    if (builtins.typeOf domains) == "list" then
      (builtins.map (i: lib.splitString "." i) domains)
    else
      (lib.splitString "." domains);

  /*
    Compare domain parts and give them a value
    If sub and base match they are valued `1`
    If sub and base don't match but base is null return `0`
    And in every other case return `-1`

    Type:
      utils.domains.compareParts :: String, Null -> String, Null -> Int
  */
  comparePart =
    # the sub domain part you want to compare
    sub:
    # the base domain part you want to compare
    base:
    if sub == base then
      1
    else if base == null then
      0
    else
      -1;

  /*
    uses fillList to generate two lists of domain parts,
    that are easily comparable. Will return attrSet like:
    ```nix
    {
      sub = [ "my" "fancy" "example" "com" ]
      base = [ null null "example" "com" ]
    }
    ```

    Type:
      utils.domains.comparableParts :: String -> String -> { sub :: [ Null, String ], base [ Null, String ] }
  */
  comparableParts =
    # subDomain you want to compare
    subDomain:
    # baseDomain you want to compare
    baseDomain:
    let
      lenSub = builtins.length subDomain;
      lenBase = builtins.length baseDomain;
      return = sub: base: {
        inherit sub;
        inherit base;
      };
    in
    if lenSub == lenBase then
      (return subDomain baseDomain)
    else if lenSub < lenBase then
      (return (utils.general.fillList subDomain (lenBase - lenSub) null) baseDomain)
    else
      (return subDomain (utils.general.fillList baseDomain (lenSub - lenBase) null));

  /*
    This returns a list like `[ 0 (-1) 1  1 ]`
    Which contains the order comparison of
    a sub domain and a base domain

    Type:
      utils.domains.rate :: [ String ] -> [ String ] -> [ Int ]
  */
  rate =
    # expects a deconstructed domain like `[ "example" "com" ]`
    subDomain:
    # expects a deconstructed domain like `[ "my" "example" "com" ]`
    baseDomain:
    let
      comp = utils.domains.comparableParts subDomain baseDomain;
    in
    lib.zipListsWith (sub: base: utils.domains.comparePart sub base) comp.sub comp.base;

  /*
    Expects a list of domain parts like `[ "ns" "example" "com" ]`
    and builds a domain from it, in this case: `ns.example.com`

    Type:
      utils.domains.construct :: [ String ] -> String
  */
  construct =
    # list of domain parts to construct
    parts: lib.concatStringsSep "." parts;

  /*
    This returns a attrSet like
    ```nix
    {
      valid = true;
      value = 2;
    }
    ```
    with `valid` telling you if the sub domain corresponds to the base domain
    and `value` telling you how close it is (higher is better)
    let's take for example: `[ "my" "example" "com" ]` as sub domain and
    `[ "example" "com" ]` as base domain, this would return the attrSet shown above.
    Because `[ "example" "com" ]` will expand to `[ null "example" "com" ]` and then
    get rated like:
    ```
    "my" == null = 0
    "example" == "example" = 1
    "com" == "com" = 1
    ```
    the domain is valid since there is no negative value and the total value is 2

    Type:
      utils.domains.validateSubDomain :: [ String ] -> [ String ] -> { valid :: Bool, value :: Int }
  */
  validateSubDomain =
    # takes the same input as `ratedDomain`
    subDomain:
    # takes the same input as `ratedDomain`
    baseDomain:
    let
      info = utils.domains.rate subDomain baseDomain;
    in
    {
      valid = !((builtins.length (builtins.filter (i: i < 0) info)) > 0);
      value = lib.foldr (a: b: a + b) 0 info;
    };

  /*
    This function takes a sub domain and a list of domains,
    and will find the most similar domain from the list.
    It does this by comparing the domain parts and not singe letters
    so if we have `sub domain.example.com` and [ `sub.example.com` `example.com` ]
    then we would get `example.com` as a result.
    If the sub domain doesn't have a matching one in the list the function will return `null`

    Type:
      utils.domains.getMostSpecific :: String -> [ String ] -> String, Null
  */
  getMostSpecific =
    # a string of a domain like `"example.com"`
    subDomain:
    #
    baseDomains:
    (lib.foldl'
      (
        placeholder: domain:
        let
          validation = utils.domains.validateSubDomain (utils.domains.getParts subDomain) domain;
        in
        if validation.valid && validation.value > placeholder.value then
          {
            domain = utils.domains.construct domain;
            inherit (validation) value;
          }
        else
          placeholder
      )
      {
        domain = null;
        value = -1;
      }
      (utils.domains.getParts baseDomains)
    ).domain;

  /*
    This Functions uses getMostSpecific to get the value of a corresponding key for a sub domain

    Type:
      utils.domains.mapBaseToSub :: String -> Attr -> String -> Any
  */
  mapBaseToSub =
    # takes a attrSet like the one provided by `networking.domains.subDomains`
    subDomain:
    # takes a attrSet like the one provided by `networking.domains.baseDomains
    baseDomains:
    # the key from which to get the value
    value:
    baseDomains.${
      utils.domains.getMostSpecific subDomain (lib.mapAttrsToList (n: v: n) baseDomains)
    }.${value};

  /*
    Be care full when using this, since you might end up overwriting previous results because if a key is defined multiple times only the last value will remain except if the value is a list then all of the content will be merged

    Type:
      utils.domains.getDomainsFromNixosConfigurations :: Attr -> Attr
  */
  getDomainsFromNixosConfigurations =
    nixosConfigurations:
    let
      baseDomains =
        lib.attrNames
          (lib.fold (l: r: lib.recursiveUpdate l r) { } (
            lib.filter (
              a:
              lib.hasAttrByPath [
                "config"
                "networking"
                "domains"
                "baseDomains"
              ] a
            ) (lib.mapAttrsToList (n: v: v) nixosConfigurations)
          )).config.networking.domains.baseDomains;
      inherit
        ((utils.general.recursiveUpdateLists (
          lib.filter (
            a:
            lib.hasAttrByPath [
              "config"
              "networking"
              "domains"
              "subDomains"
            ] a
          ) (lib.mapAttrsToList (n: v: v) nixosConfigurations)
        )).config.networking.domains
        )
        subDomains
        ;
      reducedBaseDomains = lib.fold (
        domain: acc:
        acc
        ++ (
          if (utils.domains.getMostSpecific domain (lib.subtractLists [ domain ] baseDomains)) == null then
            [ domain ]
          else
            [ ]
        )
      ) [ ] baseDomains;
      subDomainKeys = lib.attrNames subDomains;
    in
    lib.fold (
      attr: acc:
      lib.recursiveUpdate acc {
        ${(utils.domains.getMostSpecific attr reducedBaseDomains)}.${attr} = subDomains.${attr};
      }
    ) { } subDomainKeys;

  /*
    Expects a attribute-set like:
    ```nix
    {
    inherit (self) nixosConfigurations darwinConfigurations;
    extraConfig = import ./dns.nix;
    }
    ```
    it will do special casing for the keys nixosConfigurations (and potentially darwinConfiguratiosn) and every other key is expected to have a attrs that looks like the output of utils.debug
    it will then go ahead and merge all the dns configs into one.

    Type:
      utils.domains.getDnsConfig :: Attr -> Attr
  */
  getDnsConfig =
    config:
    utils.general.recursiveUpdateLists (
      builtins.attrValues
        (lib.evalModules {
          modules = [
            { inherit config; }
            ../modules/dnsConfig.nix
          ];
          specialArgs = {
            inherit utils;
          };
        }).config
    );
}
