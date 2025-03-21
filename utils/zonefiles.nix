{ lib, utils }:
{
  /*
    Converts a string into a valid txt record so it's compliant with RFC 4408
    This means it splits the string every 255 chars and surrounds it with quotation marks

    Type:
      utils.zonefiles.formatTxtRecord :: String -> String
  */
  formatTxtRecord =
    # The String of a txt resource record
    txtString:
    let
      format =
        {
          acc ? [ ],
          chars,
        }:
        let
          rest = [ (lib.concatStrings (lib.take 255 chars)) ];
        in
        if (lib.length chars) > 255 then
          format {
            acc = acc ++ rest;
            chars = lib.drop 255 chars;
          }
        else if acc != [ ] then
          acc ++ rest
        else
          rest;
      resolve = lib.concatStringsSep "\" \"" (format {
        chars = lib.stringToCharacters txtString;
      });
    in
    "\"${resolve}\"";

  /*
    attributeset
    Takes any record from the module and converts it to a fitting zonefile string

    Type:
      utils.zonefiles.convertRecordToStr :: String -> Any -> String
  */
  convertRecordToStr =
    # Record type, like a or caa
    record:
    # Record value, like "198.51.100.42"
    value:
    if record == "mx" then
      "MX ${builtins.toString value.preference} ${value.exchange}."
    else if record == "ns" then
      "NS ${value}."
    else if record == "caa" then
      "CAA ${builtins.toString value.flags} ${value.tag} ${value.value}"
    else if record == "uri" then
      "URI ${builtins.toString value.priority} ${builtins.toString value.weight} ${value.target}"
    else if record == "srv" then
      "SRV ${builtins.toString value.priority} ${builtins.toString value.weight} ${builtins.toString value.port} ${value.target}"
    else if record == "soa" then
      "SOA ${value.mname}. ${value.rname}. ( ${builtins.toString value.serial} ${builtins.toString value.refresh} ${builtins.toString value.retry} ${builtins.toString value.expire} ${builtins.toString value.ttl} )"
    else if record == "txt" then
      "TXT ${utils.zonefiles.formatTxtRecord value}"
    else if record == "tlsa" then
      "TLSA ${builtins.toString value.usage} ${builtins.toString value.selector} ${builtins.toString value.matchingType} ${value.certificateAssociationData}"
    else if record == "sshfp" then
      "SSHFP ${builtins.toString value.algorithm} ${builtins.toString value.type} ${value.fingerprint}"
    else
      "${lib.toUpper record} ${value}";
  /*
    Converts a zone attributeset into a zonefile and returns a multiline string

    Type:
      utils.zonefiles.mkZoneString :: Attr -> String
  */
  mkZoneString =
    # Takes dnsConfig."your-domain.invalid"
    entries:
    ''${lib.concatLines (
      lib.flatten (
        lib.mapAttrsToList (
          domainName: domainAttrs:
          lib.mapAttrsToList (
            recordType: record:
            (builtins.map (
              val:
              "${domainName}. IN ${builtins.toString record.ttl} ${utils.zonefiles.convertRecordToStr recordType val}"
            ) record.data)
          ) domainAttrs
        ) entries
      )
    )}'';

  /*
    Returns a zone-file from NixOS-DNS values
    Can nicely be used with lib.mapAttrsToList

    Type:
      utils.zonefiles.write :: String -> Attr -> File
  */
  write =
    # takes "your-domain.invalid"
    domainName:
    # takes dnsConfig."your-domain.invalid"
    domainValues:
    builtins.toFile domainName (utils.zonefiles.mkZoneString domainValues);
}
