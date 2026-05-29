# Modules

There is a module for NixOS and a module for extraConfig.
They both take the same record values and have the same assertions.
Please take a look at the coming pages for a list of available options.
I currently have trouble rendering the record fields if their type is a sub module,
if you are interested in any like caa or mx, you'll sadly have to take a look at [the source](https://github.com/Janik-Haag/NixOS-DNS/tree/main/modules/records.nix) for now.

Every record supports `comment` and `ttlAuto`. `comment` is a nullable string
with a 100 character limit; zonefile output renders it as a BIND comment and
Cloudflare backends can send it as provider-side metadata. `ttlAuto` asks
backends to use provider automatic TTL handling; zonefile output omits the TTL.

`proxied` is available for provider proxying and is valid only on `A`, `AAAA`,
`CNAME`, and `ALIAS` records. octoDNS metadata helpers render it as
`octodns.cloudflare.proxied = true` for Cloudflare-aware consumers. Proxied
records cannot set a non-default explicit TTL; use `ttlAuto` for provider
automatic TTL handling.
