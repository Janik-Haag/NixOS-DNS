{ self, lib, utils }:
{
  testWriteZoneFile = {
    expr = builtins.readFile (utils.zonefiles.write "example.com" {
      "example.com" = {
        a = {
          ttl = 60;
          data = [ "198.51.100.42" ];
        };
        aaaa = {
          ttl = 60;
          data = [ "2001:db8:d9a2:5198::13" ];
        };
        caa = {
          ttl = 60;
          data = [{
            flags = 0;
            tag = "issue";
            value = "letsencrypt.org";
          }];
        };
        ns = {
          ttl = 60;
          data = [
            "ns1.example.invali"
            "ns2.example.com"
            "ns3.example.org"
          ];
        };
        mx = {
          ttl = 60;
          data = [{
            exchange = "mail.example.com";
            preference = 10;
          }];
        };
        soa = {
          ttl = 60;
          data = [{
            expire = 1209600;
            mname = "ns.example.invalid";
            refresh = 7200;
            retry = 3600;
            rname = "admin.example.invalid";
            serial = 1970010100;
            ttl = 60;
          }];
        };
        txt = {
          ttl = 60;
          data = [ "v=spf1 a:mail.aq0.de -all" ];
        };
      };
      "*.example.com" = {
        alias = {
          ttl = 60;
          data = [ "example.com" ];
        };
      };
      "_ftp._tcp.example.com" = {
        uri = {
          ttl = 3600;
          data = [{
            priority = 10;
            weight = 5;
            target = "ftp://example.com/public";
          }];
        };
      };
      "_xmpp._tcp.example.com" = {
        srv = {
          ttl = 86400;
          data = [{
            priority = 10;
            weight = 5;
            port = 5223;
            target = "xmpp.example.com";
          }];
        };
      };
      "mail.example.com" = {
        cname = {
          ttl = 60;
          data = [ "e-mail.provider.invalid" ];
        };
      };
      "redirect.example.com" = {
        dname = {
          ttl = 60;
          data = [ "example.org" ];
        };
      };
    });
    expected = ''
      *.example.com. IN 60 ALIAS example.com
      _ftp._tcp.example.com. IN 3600 URI 10 5 ftp://example.com/public
      _xmpp._tcp.example.com. IN 86400 SRV 10 5 5223 xmpp.example.com
      example.com. IN 60 A 198.51.100.42
      example.com. IN 60 AAAA 2001:db8:d9a2:5198::13
      example.com. IN 60 CAA 0 issue letsencrypt.org
      example.com. IN 60 MX 10 mail.example.com.
      example.com. IN 60 NS ns1.example.invali.
      example.com. IN 60 NS ns2.example.com.
      example.com. IN 60 NS ns3.example.org.
      example.com. IN 60 SOA ns.example.invalid. admin.example.invalid. ( 1970010100 7200 3600 1209600 60 )
      example.com. IN 60 TXT "v=spf1 a:mail.aq0.de -all"
      mail.example.com. IN 60 CNAME e-mail.provider.invalid
      redirect.example.com. IN 60 DNAME example.org
    '';
  };
}
