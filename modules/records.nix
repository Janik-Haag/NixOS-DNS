{
  lib,
  utils,
  cfg,
}:
let
  mkRecord =
    defaultTTL: data:
    lib.mkOption {
      default = { };
      # this description doesn't get rendered anywhere so we can just leave it empty
      description = '''';
      type = lib.types.submodule {
        options = {
          ttl = lib.mkOption {
            description = ''
              The time to live (TTL) is a field on DNS records that tells you how
              long the record is valid (in seconds) and thus when it will be
              updated.
            '';
            example = 86400;
            default = defaultTTL;
            type = lib.types.int;
            defaultText = lib.literalExpression "Automatically use the same ttl as the matching base domain";
          };
          inherit data;
        };
      };
    };
  mkBaseRecord =
    recordType: options: mkRecord cfg.defaultTTL (lib.mkOption { default = null; } // options);
  mkSubRecord =
    recordType: options: domainName:
    mkRecord (utils.domains.mapBaseToSub domainName cfg.baseDomains recordType).ttl (
      lib.mkOption {
        default = (utils.domains.mapBaseToSub domainName cfg.baseDomains recordType).data;
        defaultText = lib.literalExpression "Automatically use the same record as the matching base domain";
      }
      // options
    );
in
lib.mapAttrs
  (
    type: func:
    lib.mapAttrs
      (n: v: func n (if (lib.hasAttrByPath [ "${type}" ] v) then (v.common // v.${type}) else v.common))
      {
        a.common = {
          description = ''
            Commonly used to map a name to a list of IPv4 addresses.
          '';
          example = "9.9.9.9";
          type = with lib.types; nullOr (coercedTo str (f: [ f ]) (listOf str)); # change me to lib.types.ipv4 once it exists
        };
        aaaa.common = {
          description = ''
            Commonly used to map a name to a list of IPv6 addresses.
          '';
          example = "2620:fe::fe";
          type = with lib.types; nullOr (coercedTo str (f: [ f ]) (listOf str)); # change me to lib.types.ipv6 once it exists
        };
        alias = {
          common = {
            description = ''
              Maps one domain name to another and uses the dns resolver of your dns server for responses.
            '';
            example = "foo.example.com";
            type =
              with lib.types;
              nullOr (oneOf [
                str
                (listOf str)
              ]); # change str to lib.types.domain once it exists
            apply = x: if x != null then lib.toList x else x;
          };
          sub = {
            apply = lib.toList;
          };
        };
        cname = {
          common = {
            description = ''
              Same as alias but the requesting party will have to resolve the response which can lead to more latency.
            '';
            example = "foo.example.com";
            type = with lib.types; nullOr str; # change str to lib.types.domain once it exists
            apply = x: if x != null then lib.toList "${x}." else x;
          };
          sub = {
            apply = lib.toList;
            type =
              with lib.types;
              nullOr (oneOf [
                str
                (listOf str)
              ]); # change str to lib.types.domain once it exists
          };
        };
        caa.common = {
          description = ''
            DNS Certification Authority Authorization, constraining acceptable CAs for a host/domain
          '';
          type =
            with lib.types;
            let
              caaSubModule = submodule {
                options = {
                  flags = lib.mkOption {
                    description = ''
                      A flags byte which implements an extensible signaling system for future use.
                      As of 2018, only the issuer critical flag has been defined, which instructs certificate authorities that they must understand the corresponding property tag before issuing a certificate.
                      This flag allows the protocol to be extended in the future with mandatory extensions, similar to critical extensions in X.509 certificates.
                    '';
                    example = 128;
                    type = int;
                  };
                  tag = lib.mkOption {
                    description = ''
                      Please take a look at [this list](https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization#Record)
                    '';
                    example = "issue";
                    type = enum [
                      "future"
                      "issue"
                      "issuewild"
                      "iodef"
                      "contactemail"
                      "contactphone"
                    ];
                  };
                  value = lib.mkOption {
                    description = ''
                      The value associated with the chosen property tag.
                    '';
                    example = "letsencrypt.org";
                    type = str;
                  };
                };
              };
            in
            nullOr (oneOf [
              caaSubModule
              (listOf (nullOr caaSubModule))
            ]);
          apply = lib.toList;
        };
        dname = {
          common = {
            description = ''
              Same as cname but also gets applied to any subdomain of the given domain
            '';
            example = "foo.example.com";
            type = with lib.types; nullOr str; # change str to lib.types.domain once it exists
            apply = x: if x != null then lib.toList x else x;
          };
          sub = {
            apply = lib.toList;
            type =
              with lib.types;
              nullOr (oneOf [
                str
                (listOf str)
              ]); # change str to lib.types.domain once it exists
          };
        };
        ns.common = {
          description = ''
            Nameserver responsible for your zone.
            Note, that this option technically allows for only one name server but I would strongly advise against that.
          '';
          example = [
            "ns1.example.com"
            "ns2.example.com"
            "ns3.example.com"
          ];
          type = with lib.types; nullOr (coercedTo str (f: [ f ]) (listOf str));
        };
        mx = {
          common = {
            description = ''
              List of mail exchange servers that accept email for this domain.
            '';
            type =
              with lib.types;
              let
                mxSubModule = submodule {
                  options = {
                    exchange = lib.mkOption {
                      description = ''
                        Name of the mailserver
                      '';
                      example = "mail1.example.com";
                      type = lib.types.str;
                    };
                    preference = lib.mkOption {
                      description = ''
                        Lower is better/more preferred over other entries.
                      '';
                      example = 10;
                      type = lib.types.int;
                    };
                  };
                };
              in
              nullOr (oneOf [
                mxSubModule
                (listOf (nullOr mxSubModule))
              ]);
            apply = lib.toList;
          };
        };
        soa = {
          common = {
            description = ''
              Specifies authoritative information about a DNS zone.
            '';
            type =
              with lib.types;
              let
                soaSubModule = submodule {
                  options = {
                    mname = lib.mkOption {
                      description = ''
                        This is the name of the primary nameserver for the zone. Secondary servers that maintain duplicates of the zone's DNS records receive updates to the zone from this primary server.
                      '';
                      example = "ns.example.com";
                      type = lib.types.str;
                    };
                    rname = lib.mkOption {
                      description = ''
                        Email of zone administrators.
                      '';
                      example = "noc@example.com";
                      type = lib.types.str;
                      apply = builtins.replaceStrings [ "@" ] [ "." ];
                    };
                    serial = lib.mkOption {
                      description = ''
                        A zone serial number is a version number for the SOA record (the higher the newer). When the serial number changes in a zone file, this alerts secondary nameservers that they should update their copies of the zone file via a zone transfer. Usually most dns-utilities working with zonefiles increment it automatically.
                      '';
                      example = "";
                      type = lib.types.int;
                    };
                    refresh = lib.mkOption {
                      description = ''
                        The length of time secondary servers should wait before asking primary servers for the SOA record to see if it has been updated.
                      '';
                      example = 86400;
                      type = lib.types.int;
                    };
                    retry = lib.mkOption {
                      description = ''
                        The length of time a server should wait for asking an unresponsive primary nameserver for an update again.
                      '';
                      example = "";
                      type = lib.types.int;
                    };
                    expire = lib.mkOption {
                      description = ''
                        If a secondary server does not get a response from the primary server for this amount of time, it should stop responding to queries for the zone.
                      '';
                      example = "";
                      type = lib.types.int;
                    };
                    ttl = lib.mkOption {
                      description = '''';
                      default = cfg.defaultTTL;
                      defaultText = lib.literalExpression "cfg.defaultTTL";
                      example = "";
                      type = lib.types.int;
                    };
                  };
                };
              in
              nullOr soaSubModule;
          };
          base = {
            apply = lib.toList;
          };
          sub = {
            default = null;
          };
        };
        spf.common =
          let
            spfText = "Spf record won't be implemented due to deprecation in RFC 7208, please use a txt record"; # todo add utils.helpers.spf or something
          in
          {
            default = null;
            description = ''
              ${spfText}
            '';
            type = lib.types.unspecified;
            apply = x: lib.throwIfNot (x == null) spfText x;
          };
        srv.common = {
          description = ''
            Specification of data in the Domain Name System defining the location, i.e., the hostname and port number, of servers for specified services. It is defined in RFC 2782.
          '';
          type =
            with lib.types;
            let
              srvSubModule = submodule {
                options = {
                  priority = lib.mkOption {
                    description = ''
                      The priority of the target host, lower value means more preferred.
                    '';
                    example = 10;
                    type = lib.types.int;
                  };
                  weight = lib.mkOption {
                    description = ''
                      Relative weight for records with the same priority, higher value means more preferred.
                    '';
                    example = 1;
                    type = lib.types.int;
                  };
                  port = lib.mkOption {
                    description = ''
                      The TCP or UDP port on which the service is to be found.
                    '';
                    example = 4731;
                    type = lib.types.int;
                  };
                  target = lib.mkOption {
                    description = ''
                      The canonical hostname of the machine providing the service.
                    '';
                    example = "example.com";
                    type = lib.types.str; # change str to lib.types.domain once it exists;
                    apply = x: "${x}.";
                  };
                };
              };
            in
            nullOr (oneOf [
              srvSubModule
              (listOf (nullOr srvSubModule))
            ]);
          apply = lib.toList;
        };
        txt.common = {
          description = ''
            Just any string, commonly used to transfer machine readable metadata.
          '';
          example = "v=DMARC1; p=none";
          type = with lib.types; nullOr (coercedTo str (f: [ f ]) (listOf str));
        };
        uri = {
          common = {
            description = ''
              Used for publishing mappings from hostnames to URIs.
            '';
            type =
              with lib.types;
              let
                uriSubModule = submodule {
                  options = {
                    priority = lib.mkOption {
                      description = ''
                        The priority of the target host, lower value means more preferred.
                      '';
                      example = 10;
                      type = lib.types.int;
                    };
                    weight = lib.mkOption {
                      description = ''
                        Relative weight for records with the same priority, higher value means more preferred.
                      '';
                      example = 1;
                      type = lib.types.int;
                    };
                    target = lib.mkOption {
                      description = ''
                        The URI of the target, where the URI is as specified in RFC 3986
                      '';
                      example = "ftp://example.com/public";
                      type = lib.types.int;
                    };
                  };
                };
              in
              nullOr (oneOf [
                uriSubModule
                (listOf (nullOr uriSubModule))
              ]);
            apply = lib.toList;
          };
        };
        tlsa = {
          common = {
            description = ''
              Used to bind X.509 certificates to domain names.
              Can be generated with the `hash-slinger` package:

              ```bash
              tlsa --create example.com --certificate /path/to/certificate.pem
              ```
            '';
            type =
              with lib.types;
              let
                tlsaSubModule = submodule {
                  options = {
                    usage = lib.mkOption {
                      description = ''
                        How to verify the certificate.
                      '';
                      example = 3;
                      type = lib.types.int;
                    };
                    selector = lib.mkOption {
                      description = ''
                        Which part of the certificate should be checked.
                      '';
                      example = 0;
                      type = lib.types.int;
                    };
                    matchingType = lib.mkOption {
                      description = ''
                        Whether to store the whole certificate in the certificate association data, or a hash of it.
                      '';
                      example = 1;
                      type = lib.types.int;
                    };
                    certificateAssociationData = lib.mkOption {
                      description = ''
                        The certificate or hash thereof to be matched, in hexadecimal format.
                      '';
                      example = "2b03e032ab48fa5cb9d87c2e4ba1dda8ff9933fd1188f80f8508e132527a3801";
                      type = lib.types.str;
                    };
                  };
                };
              in
              nullOr (oneOf [
                tlsaSubModule
                (listOf (nullOr tlsaSubModule))
              ]);
            apply = lib.toList;
          };
        };
        sshfp = {
          common = {
            description = ''
              Used to bind SSH host keys fingerprints to domain names.
              Can be generated with the `openssh` package:

              ```bash
              ssh-keyscan -D example.com
              ```
            '';
            type =
              with lib.types;
              let
                tlsaSubModule = submodule {
                  options = {
                    algorithm = lib.mkOption {
                      description = ''
                        Algorithm of the SSH host key.
                      '';
                      example = 4;
                      type = lib.types.int;
                    };
                    type = lib.mkOption {
                      description = ''
                        Algorith used to generate the fingerprint of the SSH host key.
                      '';
                      example = 1;
                      type = lib.types.int;
                    };
                    fingerprint = lib.mkOption {
                      description = ''
                        Hexadecimal fingerprint of the SSH host key.
                      '';
                      example = "035e39adea06bd15c0b4ae06375f36459a5780bc";
                      type = lib.types.str;
                    };
                  };
                };
              in
              nullOr (oneOf [
                tlsaSubModule
                (listOf (nullOr tlsaSubModule))
              ]);
            apply = lib.toList;
          };
        };
        # loc = lib.mkOption { };
        # naptr = lib.mkOption { };
        # ptr = lib.mkOption { };
        # zonemd = lib.mkOption { };
      }
  )
  {
    base = mkBaseRecord;
    sub = mkSubRecord;
  }
