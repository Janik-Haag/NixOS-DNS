# NixOS-DNS

What do you get with `NixOS-DNS`:

- ✅ NixOS module
- ✅ Utility functions
- ✅ Zonefile generation
- ✅ Octodns config generation
- ✅ Auto generated docs
- ✅ Unit tests

## Quick start

There is a usage example/template with comments in [./example](./example/flake.nix), you can try it out locally by doing:

```bash
nix flake init -t github:Janik-Haag/nixos-dns
```

## Docs

View the docs [here](https://janik-haag.github.io/NixOS-DNS/)
Or view it locally:

```bash
nix build github:Janik-Haag/nixos-dns#docs && xdg-open result/index.html
```

## Motivation

I started using octodns as dns deployment tool some time ago which works like a charm.
But it bothered me that every time I wrote a new service config, I had to not just go and define the domain in the module but also in the octodns config.
Which got particularly annoying because of context switches between nix and yaml.
But not just that, it also prevented me from using nix's awesome versatility when it comes to dns,
for example I have a `prometheus-node-exporter.nix` which gets imported by every server in my flake,
and has a let binding at the top defining:

```nix
domain = "${config.networking.hostName}.prometheus.${config.networking.domain}";
```

which automatically generates a domain like `myHost1.prometheus.example.com` for every server that imports it.
There is just a small problem: I now also have to add a entry for every host to my octodns config, which also makes the nixos module less portable.
So I had the idea of writing a NixOS module that provides domain meta data per host and per module, to automagically generate dns entries from.
Which ended up as `networking.domains.baseDomains` and `networking.domains.subDomains`. The idea is that you use `baseDomains` on a per host basis which will
define the default value for every subDomain that matches a baseDomain,
and then use `subDomains` in your modules.
