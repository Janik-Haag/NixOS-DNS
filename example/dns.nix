{
  defaultTTL = 86400;
  zones = {
    "example.com" = {
      "" = {
        soa = {
          data = {
            rname = "admin.example.invalid";
            mname = "ns.example.invalid";
            serial = 1970010100;
            refresh = 7200;
            retry = 3600;
            ttl = 60;
            expire = 1209600;
          };
        };
        ns = {
          data = [
            "ns1.invalid"
            "ns2.invalid"
            "ns3.invalid"
          ];
        };
        txt = {
          data = [
            "meow"
            "v=spf1 a:mail.example.com -all"
          ];
        };
      };
      "mail._domainkey".txt.data = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2WJ46bl9UqBY9ZxqkVCBdSiysIJMUbWS3BK10Lupe4T5+jWAcdzJraznWeaVF/mR/9TyiB7lE79ZB6WxHxTwwJ5UZjURwImKAKqSGPXPACIj+LHyx5j2nHN4CawC6bkCmpGT99B7I/5bCelekoAHV9U/4pE2YEjgA0VxvlSKHB2Y7cPWL303DInYGaTrvMczuwLYoEwIiBirffYNqHyrOJE9A+ZQRdLjM8DFOxegAOV9mcHb3MwneJuu86Czz45UIrQ7AxkMUNKgHitqTSnXzLWd4BF6Kf3XUh/lED7WPdviBLJo/1H0Cgch8RRlinTeDVliHDQ6/zLWpk6+k3iKkQIDAQAB; s=*;";
    };
    "example.net" = {
      "" = {
        a = {
          data = [ "203.0.113.73" ];
          ttl = 60;
        };
      };
    };
    "example.invalid" = {
      "" = {
        a = {
          data = [ "198.51.100.35" ];
          ttl = 60;
        };
        aaaa = {
          data = [ "2001:DB8:42fc::64" ];
          ttl = 60;
        };
      };
      "redirect".cname.data = "example.net";
    };
  };
}
