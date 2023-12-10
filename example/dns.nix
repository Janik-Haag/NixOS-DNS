{
  defaultTTL = 86400;
  zones = {
    "example.com" = {
      "" = {
        ns = {
          data = [ "ns1.invalid" "ns2.invalid" "ns3.invalid" ];
        };
      };
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
