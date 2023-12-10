{ self, lib, utils }: {
  testGetDomainPartsString = {
    expr = utils.domains.getParts "my.example.com";
    expected = [ "my" "example" "com" ];
  };
  testGetDomainPartsList = {
    expr = utils.domains.getParts [ "my.example.com" "example.net" ];
    expected = [ [ "my" "example" "com" ] [ "example" "net" ] ];
  };

  testCompareDomainPartPositive = {
    expr = utils.domains.comparePart "example" "example";
    expected = 1;
  };
  testCompareDomainPartNegative = {
    expr = utils.domains.comparePart "org" "com";
    expected = -1;
  };
  testCompareDomainPartNeutral = {
    expr = utils.domains.comparePart "subdomain" null;
    expected = 0;
  };

  testComparableDomainPartsSame = {
    expr = utils.domains.comparableParts [ "example" "net" ] [ "example" "org" ];
    expected = {
      sub = [ "example" "net" ];
      base = [ "example" "org" ];
    };
  };
  testComparableDomainPartsSub = {
    expr = utils.domains.comparableParts [ "example" "net" ] [ "my" "example" "org" ];
    expected = {
      sub = [ null "example" "net" ];
      base = [ "my" "example" "org" ];
    };
  };
  testComparableDomainPartsBase = {
    expr = utils.domains.comparableParts [ "my" "example" "net" ] [ "example" "org" ];
    expected = {
      sub = [ "my" "example" "net" ];
      base = [ null "example" "org" ];
    };
  };

  testRateDomain = {
    expr = utils.domains.rate [ "subdomain" "xample" "com" ] [ "example" "com" ];
    expected = [ 0 (-1) 1 ];
  };

  testConstructDomain = {
    expr = utils.domains.construct [ "my" "example" "com" ];
    expected = "my.example.com";
  };

  testValidateSubDomainValid = {
    expr = utils.domains.validateSubDomain [ "subdomain" "example" "com" ] [ "example" "com" ];
    expected = {
      valid = true;
      value = 2;
    };
  };
  testValidateSubDomainInvalid = {
    expr = utils.domains.validateSubDomain [ "subdomain" "xample" "com" ] [ "example" "com" ];
    expected = {
      valid = false;
      value = 0;
    };
  };

  testGetMostSpecificValid = {
    expr = utils.domains.getMostSpecific "subdomain.example.com" [ "example.com" "subdomain.example.com" ];
    expected = "subdomain.example.com";
  };
  testGetMostSpecificInvalid = {
    expr = utils.domains.getMostSpecific "subdomain.example.com" [ "xample.com" ];
    expected = null;
  };

  testMapBaseToSub = {
    expr =
      utils.domains.mapBaseToSub "sub.my.example.com"
        {
          "example.net" = {
            a = "10.10.10.10";
            aaaa = "fe80::1";
          };
          "example.com" = {
            a = "10.10.10.10";
            aaaa = "fe80::1";
          };
          "my.example.com" = {
            a = "10.10.10.20";
            aaaa = "fe80::2";
          };
        } "aaaa";
    expected = "fe80::2";
  };

  # automatically tested through utils.domains.getDnsConfig
  # testGetDomainsFromNixosConfigurations

  testGetDnsConfig = {
    expr = utils.domains.getDnsConfig (import ./resources/dnsConfig.nix { inherit self lib utils; });
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
      };
    };
  };
}
