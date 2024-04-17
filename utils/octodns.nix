{ lib, utils }:
{
  /*
    Just adds a dummy SOA record.
    It won't actually be used by anything.
    But the octodns bind module has a check for the validity of a zone-file
    and a zone-file MUST have a SOA record.
    Anyways, octodns will just ignore its existence and only sync supported records.

    Type:
      utils.octodns.fakeSOA :: Attr -> Attr
  */
  fakeSOA =
    # takes the dnsConfig module
    dnsConfig:
    lib.mapAttrs (
      zone: entries:
      if
        (lib.hasAttrByPath [
          zone
          "soa"
        ] entries)
      then
        entries
      else
        (lib.recursiveUpdate entries {
          ${zone}.soa = {
            ttl = 60;
            data = [
              {
                rname = "admin.example.invalid";
                mname = "ns.example.invalid";
                serial = 1970010100;
                refresh = 7200;
                retry = 3600;
                ttl = 60;
                expire = 1209600;
              }
            ];
          };
        })
    ) dnsConfig;

  /*
    Same thing as generate.octodnsConfig but instead of returning a derivation it returns a set ready for converting it to a file.

    Type:
      utils.octodns.makeConfigAttrs :: Attr -> Attr
  */
  makeConfigAttrs =
    # Takes the same attrset input as generate.octodnsConfig
    settings:
    lib.recursiveUpdate settings.config (
      {
        providers = {
          config = {
            class = "octodns_bind.ZoneFileSource";
            # gets overwritten at the build step
            directory = null;
            # by default the files are supposed to be called `$zone.` this makes it so it's only `$zone`
            file_extension = "";
          };
        };
        inherit (settings) zones;
        # dirty hack that should probably be refactored.. this should probably just be a module..
      }
      // (if builtins.hasAttr "manager" settings then { inherit (settings) manager; } else { })
    );

  generateZoneAttrs = targets: {
    sources = [ "config" ];
    inherit targets;
  };
}
