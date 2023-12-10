{
  description = "A example on how one can use nixos-dns";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-dns.url = "github:Janik-Haag/nixos-dns";
    nixos-dns.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , nixos-dns
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      dnsConfig = {
        inherit (self) nixosConfigurations;
        extraConfig = import ./dns.nix;
      };
    in
    {
      nixosConfigurations = {
        host1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-dns.nixosModules.dns
            ./hosts/host1.nix
          ];
        };
        host2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-dns.nixosModules.dns
            ./hosts/host2.nix
          ];
        };
      };

      # nix eval .#dnsDebugHost
      dnsDebugHost = nixos-dns.utils.debug.host self.nixosConfigurations.host1;

      # nix eval .#dnsDebugConfig
      dnsDebugConfig = nixos-dns.utils.debug.config dnsConfig;

      packages = forAllSystems (system:
        let
          generate = nixos-dns.utils.generate nixpkgs.legacyPackages.${system};
        in
        {
          # nix build .#zoneFiles
          zoneFiles = generate.zoneFiles dnsConfig;

          # nix build .#octodns
          octodns = generate.octodnsConfig {
            inherit dnsConfig;
            config = {
              providers = {
                powerdns = {
                  class = "octodns_powerdns.PowerDnsProvider";
                  host = "ns.dns.invalid";
                  api_key = "env/POWERDNS_API_KEY";
                };
              };
            };
            zones = {
              "example.com." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
              "example.org." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
              "missing.invalid." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
            };
          };
        }
      );
    };
}
