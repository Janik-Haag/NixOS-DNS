{ self, lib, utils }:
let
  dnsConfig = import ./resources/dnsConfig.nix { inherit self lib utils; };
in
{
  testHost = {
    expr = utils.debug.host dnsConfig.nixosConfigurations.host1;
    expected = {
      "example.com" = {
        "host1.example.com" = {
          a = { data = [ "198.51.100.1" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::1" ]; ttl = 86400; };
        };
        "www.example.com" = {
          a = { data = [ "198.51.100.1" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::1" ]; ttl = 86400; };
        };
      };
    };
  };
  testConfig = {
    expr = utils.debug.config dnsConfig;
    expected = {
      "example.com" = {
        "example.com" = {
          ns = { data = [ "ns1.invalid" "ns2.invalid" "ns3.invalid" ]; ttl = 60; };
        };
        "host1.example.com" = {
          a = { data = [ "198.51.100.1" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::1" ]; ttl = 86400; };
        };
        "host2.example.com" = {
          a = { data = [ "198.51.100.2" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::2" ]; ttl = 86400; };
        };
        "host4.example.com" = {
          a = { data = [ "198.51.100.4" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::4" ]; ttl = 86400; };
        };
        "www.example.com" = {
          a = { data = [ "198.51.100.1" "198.51.100.2" ]; ttl = 86400; };
          aaaa = { data = [ "2001:db8:d9a2:5198::1" "2001:db8:d9a2:5198::2" ]; ttl = 86400; };
        };
      };
      "example.org" = {
        "example.org" = {
          cname = { data = [ "www.example.com" ]; ttl = 60; };
        };
        "_xmpp._tcp.example.org" = {
          srv = { data = [ { port = 5223; priority = 10; weight = 5; target = "host1.example.com."; } ]; ttl = 60; };
        };
      };
    };
  };
}
