{ lib, utils }:
{
  /*
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
      "TXT \"${value}\""
    else
      "${lib.toUpper record} ${value}";
  mkZoneString =
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
