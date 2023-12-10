{
  boot.isContainer = true; # Hack to have an easy time building
  system.stateVersion = "23.11";
  networking.domains = {
    enable = true;
    baseDomains = {
      "specific.example.org" = {
        a.data = "203.0.113.65";
        aaaa.data = "2001:db8:e2:c3::37";
      };
      "example.org" = {
        a.data = "203.0.113.65";
        aaaa.data = "2001:db8:e2:c3::37";
      };
      "example.net" = {
        a.data = "203.0.113.65";
        aaaa.data = "2001:db8:e2:c3::37";
      };
      "example.com" = {
        a.data = "203.0.113.65";
        aaaa.data = "2001:db8:e2:c3::37";
      };
    };
    subDomains = {
      "example.com" = {
        mx.data = [
          {
            preference = 10;
            exchange = "mail1.example.com";
          }
        ];
      };
      "example.net" = { };
      "mail.example.com" = { };
      "specific.example.org" = { };
      "monitoring.example.com" = { };
      "monitoring.example.net" = { };
      "monitoring.example.org" = { };
    };
  };
}
