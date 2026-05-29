{
  self,
  lib,
  utils,
}:
let
  evalExtraConfig =
    extraConfig:
    builtins.tryEval (builtins.deepSeq (utils.domains.getDnsConfig { inherit extraConfig; }) true);
in
{
  testProxiedTxtRecordFails = {
    expr =
      (evalExtraConfig {
        defaultTTL = 300;
        zones."example.com"."".txt = {
          data = "not proxiable";
          proxied = true;
        };
      }).success;
    expected = false;
  };

  testTtlAutoWithExplicitTtlFails = {
    expr =
      (evalExtraConfig {
        defaultTTL = 86400;
        zones."example.com"."".a = {
          data = "198.51.100.42";
          ttl = 300;
          ttlAuto = true;
        };
      }).success;
    expected = false;
  };

  testProxiedWithExplicitTtlFails = {
    expr =
      (evalExtraConfig {
        defaultTTL = 86400;
        zones."example.com"."".a = {
          data = "198.51.100.42";
          ttl = 300;
          proxied = true;
        };
      }).success;
    expected = false;
  };

  testCommentLongerThan100Fails = {
    expr =
      (evalExtraConfig {
        defaultTTL = 300;
        zones."example.com"."".txt = {
          data = "too much commentary";
          comment = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        };
      }).success;
    expected = false;
  };

  testSchemaFieldsSurviveWhenSet = {
    expr = utils.domains.getDnsConfig {
      extraConfig = {
        defaultTTL = 300;
        zones."example.com"."".a = {
          data = "198.51.100.42";
          comment = "front door";
          proxied = true;
          ttlAuto = true;
        };
      };
    };
    expected = {
      "example.com"."example.com".a = {
        data = [ "198.51.100.42" ];
        ttl = 300;
        comment = "front door";
        proxied = true;
        ttlAuto = true;
      };
    };
  };

  testUriTargetAcceptsString = {
    expr = utils.domains.getDnsConfig {
      extraConfig = {
        defaultTTL = 300;
        zones."example.com"."_ftp._tcp".uri = {
          data = {
            priority = 10;
            weight = 1;
            target = "ftp://example.com/public";
          };
        };
      };
    };
    expected = {
      "example.com"."_ftp._tcp.example.com".uri = {
        data = [
          {
            priority = 10;
            target = "ftp://example.com/public";
            weight = 1;
          }
        ];
        ttl = 300;
      };
    };
  };
}
