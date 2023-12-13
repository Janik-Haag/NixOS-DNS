# Usage
For all the modules options take a look [here](modules/index.md).
And there is a quite elaborate example [here](https://github.com/Janik-Haag/nixos-dns/tree/main/example), you can also use it as a template by doing: `nix flake init -t github:Janik-Haag/nixos-dns`.

## classic

There is a `default.nix` in the project root with `flake-compat`, I was told that it should be enough to use it in a classical NixOS environment, but have no idea how to do so (probably adding a channel?).
This would probably be a easy contribution if you are more familiar.

## flakes

```nix
{
  # You of course have to add the `nixos-dns` input like:
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-dns.url = "github:Janik-Haag/nixos-dns";
    nixos-dns.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Nothing special here
  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-dns
  }: let
    # You probably know this but flake outputs are architecture dependent,
    # so we use this little helper function. Many people use `github:numtide/flake-utils` for that.
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in {
    # Your NixOS configurations
    nixosConfigurations = {
      exampleHost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Note that we are importing the nixos-dns module here
          nixos-dns.nixosModules.dns
          ./hosts/exampleHost.nix
        ];
      };
    };

    # We are adding this as package since the zoneFile output is architecture dependent
    packages = forAllSystems (system:
      let
        # `nixos-dns.utils.generate` is a function taking in pkgs as argument
        # and returns a set of functions that are architecture dependent like writing zoneFiles
        generate = nixos-dns.utils.generate nixpkgs.legacyPackages.${system};
      in
        # the attrset `generate.zoneFiles` get passed here is the default interface for dnsConfigs with nixos-dns
        # and anything from the debugging functions, `generate.octodnsConfig` and zoneFiles uses it.
        zoneFiles = generate.zoneFiles {
          inherit (self) nixosConfigurations;
          extraConfig = import ./dns.nix;
        };
      }
    )
  };
}
```

## NixOS Module

NixOS-DNS was built to decouple modules even more from their host.
To achieve this we have the concept of `baseDomains` and `subDomains`.

In a nixos hosts configuration you would do something like:

```nix
  networking.hostName = "example-host";
  networking.domains = {
    enable = true;
    baseDomains = {
      "example.com" = {
        a.data = "203.0.113.42";
        aaaa.data = "2001:db8:1c1b:c00e::1";
      };
    };
  };
```

This enables the `networking.domains` module.
And registers the baseDomain `example.com` with the `a` and `aaaa` records set.
You might notice the `.data` behind any record, this is because you might want to set the ttl different based on record type.
As you can see above the `.ttl` isn't specifically added to every record, this is because there is `networking.domains.defaultTTL`
So every `record` has two fields `ttl` and `data`, the data type differs based on the record, for more info please refer to the module docs.

And inside of a module you would do something like:
```nix
  networking.domains.subDomains."grafana.example.com" = { };
```

So this would produce this set:
```nix
{
  "example.com" = {
    "grafana.example.com" = {
      a = {
        ttl = 86400;
        data = "203.0.113.42";
      };
      aaaa = {
        ttl = 86400;
        data = "2001:db8:1c1b:c00e::1";
      };
    };
  };
}
```

> **note**
>
> baseDomains and their records don't end up in zone files, octodns configs, or any other output for that matter
> So in the example above for "example.com" to end up in a zone file you would have to add:
> ```nix
>   networking.domains.subDomains."example.com" = { };
> ```
> to the hosts configuration.

Nix supports `${}` operations inside of attrsets, so you can get creative and do stuff like:
```nix
  networking.domains.subDomains."${networking.hostname}.example.com" = { };
  networking.domains.subDomains."*.${networking.hostname}.example.com" = { };
  networking.domains.subDomains."${networking.hostname}.prometheus.example.com" = { };
```

NixOS-DNS does a bunch of magic to automatically map subDomains to their closest baseDomain and throws an error if there is no matching baseDomain.
So if we have:
```nix
  networking.domains.baseDomains = {
    "example.net" = {};
    "example.com" = {};
    "domain.example.com" = {};
    "subdomain.example.com" = {};
  };
```
and:
```nix
  networking.domains.baseDomains = {
    "example.com" = {};
    "mydomain.example.com" = {};
    "cats.subdomain.example.com" = {};
  };
```

We would get:

| subDomains                     | matches                   |
| ------------------------------ | ------------------------- |
| `"example.com"`                | `"example.com"`           |
| `"mydomain.example.com"`       | `"example.com"`           |
| `"cats.subdomain.example.com"` | `"subdomain.example.com"` |

And `example.net` just wouldn't get matched, but that's fine since it is a baseDomain, if it were a subDomain it would cause an error.

## extraConfig

You probably want to add some more information, to do so you can use the extraConfiguration key in the dnsConfig.
Please take a look at [the example](https://github.com/Janik-Haag/nixos-dns/tree/main/example/dns.nix) for usage information.

All the hosts in `nixosConfigurations` and `extraConfig` get merged and nothing gets overwritten.
So if you define multiple domains with the same records all the record data gets merged.

## octodns

NixOS-DNS has native octodns support.
To use it add a package like the zoneFiles one above just for octodns using `generate.octodnsConfig` which expects a attrSet with a `dnsConfig`, a `config` and a zones key.
This would look like:

```nix
...
octodns = generate.octodnsConfig {
  # this is the same attr we pass to zoneFiles
  dnsConfig = {
    inherit (self) nixosConfigurations;
    extraConfig = import ./dns.nix;
  };
  # the octodns config key
  config = {
    providers = {
      # adding a provider to push to
      powerdns = {
        class = "octodns_powerdns.PowerDnsProvider";
        host = "ns.dns.invalid";
        # reads the env var from your shell
        api_key = "env/POWERDNS_API_KEY";
      };
    };
  };
  zones = {
    # `nixos-dns.utils.octodns.generateZoneAttrs` is a helper function
    # generating the correct values for usage with NixOS-DNS
    # this is the only place in nixos-dns having trailing dots
    # this was left in so we have a one to one map of the octodns values
    "example.com." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
    "example.org." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
    "missing.invalid." = nixos-dns.utils.octodns.generateZoneAttrs [ "powerdns" ];
  };
};
...
```

With the example above we at least need the octodns bind and powerdns provider.
The powerdns provider is needed because it's used in the example.
NixOS-DNS uses the bind provider internally, since it can reads zone-files, so we also need that.
We do this because it is a lot less maintenance and less likely to have bugs instead of also maintaining a nixos-dns to octodns internal yaml builder.

You can run the example below to check if your config works, just make sure to do a `nix build /your/nixos/config#octodns` before and replace `example.com.` (note the trailing dot) with your domain.
```bash
nix-shell -p 'octodns.withProviders (ps: [ octodns-providers.bind octodns-providers.powerdns ])' --run "POWERDNS_API_KEY="" octodns-dump --config-file=./result --output-dir=/tmp/octodns_dump example.com. config"
cat /tmp/octodns_dump/example.com.yaml
```

Please refer to the [octodns documentation](https://github.com/octodns/octodns#getting-started) for more information, the values should map one to one to nixos-dns.

## Updating

We want to strongly encourage you to take a look at the [CHANGELOG.md](https://github.com/Janik-Haag/nixos-dns/tree/main/CHANGELOG.md) before updating.
Other then that the updates should be as straight forward as any other NixOS updates.
