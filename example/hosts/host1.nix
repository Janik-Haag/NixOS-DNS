{
  boot.isContainer = true; # Hack to have an easy time building
  system.stateVersion = "23.11";
  networking.domains = {
    enable = true;
    baseDomains = {
      "specific.example.org" = {
        a.data = "198.51.100.42";
        aaaa.data = "2001:db8:d9a2:5198::13";
      };
      "example.org" = {
        a.data = "198.51.100.42";
        aaaa.data = "2001:db8:d9a2:5198::13";
      };
      "example.net" = {
        a.data = "198.51.100.42";
        aaaa.data = "2001:db8:d9a2:5198::13";
      };
      "example.com" = {
        a.data = "198.51.100.42";
        aaaa.data = "2001:db8:d9a2:5198::13";
      };
    };
    subDomains = {
      "example.com" = {
        mx.data = {
          preference = 10;
          exchange = "mail1.example.com";
        };
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
