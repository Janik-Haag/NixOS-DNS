# Contributing/Development

First of all thank you for considering to contribute to this Project.
If you want to just fix a small thing or add a tiny function feel free to open a PR and I'll probably just merge it after review. You can of course also open a issue.
If you are thinking about doing a larger thing, for example adding dnscontrol support consider opening a issue first or doing a draft PR so we can talk about implantation details beforehand.

| Tooling                                                                  | Usage Example                                    |
| ------------------------------------------------------------------------ | ------------------------------------------------ |
| [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) as formatter | `nix fmt`                                        |
| [statix](https://github.com/NerdyPepper/statix) as linter                | `statix check`                                   |
| [nix-unit](https://github.com/nix-community/nix-unit) for unit tests     | `nix-unit --flake .#tests`                       |
| [nixdoc](https://github.com/nix-community/nixdoc) for documentation      | `nix build .#docs && xdg-open result/index.html` |

all of these are in the projects nix devshell so just run `nix develop` or `direnv allow` and they will be available in your shell.

## modules

Uses the same module system as nixpkgs.
Documentation builds fail if any description field is empty, so be sure to add one.
If a default module value is not a primary data type but tries to evaluate a function add the defaultText string,
otherwise documentation builds will fail.

Please document breaking changes in the `CHANGELOG.md`

## utils

Every function is documented using [nixdoc](https://github.com/nix-community/nixdoc).
Please refer to the nixdoc readme for a howto or copy existing functions.

And every function has at least one unit test, ensuring that it works.
You can find the tests in `utils/test-*.nix`

### Modifying a existing function

- update unit-tests
- update documentation
- add breaking changes to `CHANGELOG.md`

### Adding a new function

- add a unit-test
- add documentation

### Deleting a function

- remove corresponding unit-tests
- add breaking changes to `CHANGELOG.md`


## docs

The docs are being built using [mdBook](https://github.com/rust-lang/mdBook), the build process is abstracted away into a nix derivation that outputs a static rendering of the book.
You can find the book files in `docs/book`, all the files there get copied into the book and can be written like any other mdBook.
While building the book, the deviations `docs/utils.nix` and `docs/modules.nix` also get built which generate the markdown for the utility functions and modules using nixdoc and the modules system builtin documentation system.

You can build the docs locally by doing:
```bash
nix build .#docs && xdg-open result/index.html
```

When adding any examples please use the resources linked in the table below:

| Resources reserved for documentation | Related RFC                                              |
|------------------------------------- | -------------------------------------------------------- |
| Domains                              | [RFC2606](https://datatracker.ietf.org/doc/html/rfc2606) |
| IPv6                                 | [RFC3849](https://datatracker.ietf.org/doc/html/rfc3849) |
| IPv4                                 | [RFC5737](https://datatracker.ietf.org/doc/html/rfc5737) |
