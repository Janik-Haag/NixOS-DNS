{ self, lib, utils }:
let
  defaultConfig = {
    boot.isContainer = true; # Hack to have an easy time building
    system.stateVersion = "23.11";
    networking.domains.defaultTTL = 86400;
  };
in
{
  extraConfig = {
    defaultTTL = 60;
    zones = {
      "example.com" = {
        "" = {
          ns.data = [ "ns1.invalid" "ns2.invalid" "ns3.invalid" ];
        };
      };
      "example.org" = {
        "" = {
          cname.data = "www.example.com";
        };
      };
    };
  };
  nixosConfigurations = {
    host1 = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.dns
        (lib.recursiveUpdate defaultConfig {
          networking.domains = {
            enable = true;
            baseDomains = {
              "example.com" = {
                a.data = "198.51.100.1";
                aaaa.data = "2001:db8:d9a2:5198::1";
              };
            };
            subDomains."host1.example.com" = { };
            subDomains."www.example.com" = { };
          };
        })
      ];
    };
    host2 = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.dns
        (lib.recursiveUpdate defaultConfig {
          networking.domains = {
            enable = true;
            baseDomains = {
              "example.com" = {
                a.data = "198.51.100.2";
                aaaa.data = "2001:db8:d9a2:5198::2";
              };
            };
            subDomains."host2.example.com" = { };
            subDomains."www.example.com" = { };
          };
        })
      ];
    };
    host3 = lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.dns
        (lib.recursiveUpdate defaultConfig {
          networking.domains = {
            enable = false;
            baseDomains = {
              "example.com" = {
                a.data = "198.51.100.3";
                aaaa.data = "2001:db8:d9a2:5198::3";
              };
            };
            subDomains."host3.example.com" = { };
          };
        })
      ];
    };
    host4 = lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.dns
        (lib.recursiveUpdate defaultConfig {
          networking.domains = {
            enable = true;
            baseDomains = {
              "example.com" = {
                a.data = "198.51.100.4";
                aaaa.data = "2001:db8:d9a2:5198::4";
              };
            };
            subDomains."host4.example.com" = { };
          };
        })
      ];
    };
  };
}
