# Debugging

## nixos-dns

In the [example/flake.nix](https://github.com/Janik-Haag/nixos-dns/tree/main/example/flake.nix) you will find:

```nix
  # nix eval .#dnsDebugHost
  dnsDebugHost = nixos-dns.utils.debug.host self.nixosConfigurations.host1;

  # nix eval .#dnsDebugConfig
  dnsDebugConfig = nixos-dns.utils.debug.config dnsConfig;
```

Executing either of the two will print a attrset of all the merged values that will be used in your config.
You can just copy them in to your own flake and change dnsConfig/host1 to the one you actually want to debug.

> **Note**
>
> You can pipe the output of `nix eval` to nixfmt for pretty printing and into bat for syntax highlighting
> That could look Like `bat -pP -l=nix <(nix eval .#dnsDebugHost | nixfmt)`

## zone files

You can use `named-checkzone` from the `bind` package like:

```bash
# named-checkzone zonename zonefile
named-checkzone example.com result/example.com
```

to check the validity of your zone file.

## octodns config

You can use octodns-dump as described in the octodns usage [section](usage.html#octodns).
Other then that you are pretty much on your own, sorry. (but feel free to open a issue)
