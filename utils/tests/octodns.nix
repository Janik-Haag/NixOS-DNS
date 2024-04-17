{
  self,
  lib,
  utils,
}:
{
  testMakeConfigAttrs = {
    expr = utils.octodns.makeConfigAttrs {
      dnsConfig = import ./resources/dnsConfig.nix { inherit self lib utils; };
      config = {
        providers = {
          powerdns = {
            class = "octodns_powerdns.PowerDnsProvider";
            host = "ns.dns.invalid";
            api_key = "env/POWERDNS_API_KEY";
          };
        };
      };
      zones = { };
    };
    expected = {
      providers = {
        config = {
          class = "octodns_bind.ZoneFileSource";
          directory = null;
          file_extension = "";
        };
        powerdns = {
          api_key = "env/POWERDNS_API_KEY";
          class = "octodns_powerdns.PowerDnsProvider";
          host = "ns.dns.invalid";
        };
      };
      zones = { };
    };
  };

  testGenerateZoneAttrs = {
    expr = utils.octodns.generateZoneAttrs [ "powerdns" ];
    expected = {
      sources = [ "config" ];
      targets = [ "powerdns" ];
    };
  };

  testFakeSOA = {
    expr = utils.octodns.fakeSOA {
      "example.com" = {
        "example.com" = {
          ns = {
            data = [
              "ns1.invalid"
              "ns2.invalid"
              "ns3.invalid"
            ];
            ttl = 60;
          };
        };
        "host1.example.com" = {
          a = {
            data = [ "198.51.100.1" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::1" ];
            ttl = 86400;
          };
        };
        "host2.example.com" = {
          a = {
            data = [ "198.51.100.2" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::2" ];
            ttl = 86400;
          };
        };
        "host3.example.com" = {
          a = {
            data = [ "198.51.100.3" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::3" ];
            ttl = 86400;
          };
        };
        "host4.example.com" = {
          a = {
            data = [ "198.51.100.4" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::4" ];
            ttl = 86400;
          };
        };
        "www.example.com" = {
          a = {
            data = [
              "198.51.100.1"
              "198.51.100.2"
            ];
            ttl = 86400;
          };
          aaaa = {
            data = [
              "2001:db8:d9a2:5198::1"
              "2001:db8:d9a2:5198::2"
            ];
            ttl = 86400;
          };
        };
      };
      "example.org" = {
        "example.org" = {
          cname = {
            data = [ "www.example.com" ];
            ttl = 60;
          };
        };
      };
    };
    expected = {
      "example.com" = {
        "example.com" = {
          ns = {
            data = [
              "ns1.invalid"
              "ns2.invalid"
              "ns3.invalid"
            ];
            ttl = 60;
          };
          soa = {
            data = [
              {
                expire = 1209600;
                mname = "ns.example.invalid";
                refresh = 7200;
                retry = 3600;
                rname = "admin.example.invalid";
                serial = 1970010100;
                ttl = 60;
              }
            ];
            ttl = 60;
          };
        };
        "host1.example.com" = {
          a = {
            data = [ "198.51.100.1" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::1" ];
            ttl = 86400;
          };
        };
        "host2.example.com" = {
          a = {
            data = [ "198.51.100.2" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::2" ];
            ttl = 86400;
          };
        };
        "host3.example.com" = {
          a = {
            data = [ "198.51.100.3" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::3" ];
            ttl = 86400;
          };
        };
        "host4.example.com" = {
          a = {
            data = [ "198.51.100.4" ];
            ttl = 86400;
          };
          aaaa = {
            data = [ "2001:db8:d9a2:5198::4" ];
            ttl = 86400;
          };
        };
        "www.example.com" = {
          a = {
            data = [
              "198.51.100.1"
              "198.51.100.2"
            ];
            ttl = 86400;
          };
          aaaa = {
            data = [
              "2001:db8:d9a2:5198::1"
              "2001:db8:d9a2:5198::2"
            ];
            ttl = 86400;
          };
        };
      };
      "example.org" = {
        "example.org" = {
          cname = {
            data = [ "www.example.com" ];
            ttl = 60;
          };
          soa = {
            data = [
              {
                expire = 1209600;
                mname = "ns.example.invalid";
                refresh = 7200;
                retry = 3600;
                rname = "admin.example.invalid";
                serial = 1970010100;
                ttl = 60;
              }
            ];
            ttl = 60;
          };
        };
      };
    };
  };
}
