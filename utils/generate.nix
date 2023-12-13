/*
  This is a bit of a special thing since unlike every other `utils.*` namespace this is not a set but a function returning a set.
  The only function input is pkgs and it expects the nixpkgs package set. This is done in this way to keep this functions pure.
*/
{ lib, utils }: pkgs:
let
  writeYaml = name: value: (pkgs.formats.yaml { }).generate name value;
  generate = utils.generate pkgs;
in
{

  /*
    Generates zonefiles from dnsConfig

    Type:
      utils.generate.zoneFiles :: Attr -> [ Files ]
  */
  zoneFiles =
    # expects the dnsConfig module output as a input
    config:
    generate.linkZoneFiles (utils.domains.getDnsConfig config);

  /*
    Type:
      utils.generate.linkZoneFiles :: Attr -> [ Files ]
  */
  linkZoneFiles =
    # takes the output from utils.domains.getDnsConfig
    config:
    pkgs.linkFarm "zones" (lib.mapAttrsToList
      (
        name: value: {
          inherit name;
          path = utils.zonefiles.write name value;
        }
      )
      config);
  /*
    Takes a Attrset like
    ```nix
      {
        inherit dnsConfig;
        config = { };
        zones = { };

        # optionally
        manager = { };
      }
    ```
    Everything except for dnsConfig is a 1:1 map of the octodns config yaml described in their docs.
  */
  octodnsConfig =
    # The required config
    config:
    let
      cfg = utils.octodns.makeConfigAttrs config;
    in
    writeYaml "config.yaml" (
      lib.recursiveUpdate cfg {
        providers.config.directory = generate.linkZoneFiles (utils.octodns.fakeSOA (utils.domains.getDnsConfig config.dnsConfig));
      }
    );
}
