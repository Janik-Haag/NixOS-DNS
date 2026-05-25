{
  description = "A flake providing Nix/OS dns utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-compat,
      systems,
      treefmt-nix,
    }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
      testFiles = nixpkgs.lib.filterAttrs (
        name: type: type == "regular" && nixpkgs.lib.hasSuffix ".nix" name
      ) (builtins.readDir ./utils/tests);
      testSuites = nixpkgs.lib.mapAttrs' (
        name: _:
        let
          testFile = import "${./utils}/tests/${name}";
          args = {
            inherit self;
            inherit (nixpkgs) lib;
            inherit (self) utils;
          };
        in
        nixpkgs.lib.nameValuePair (nixpkgs.lib.removeSuffix ".nix" name) (
          testFile (builtins.intersectAttrs (builtins.functionArgs testFile) args)
        )
      ) testFiles;
      checkedTests = builtins.deepSeq (nixpkgs.lib.mapAttrsRecursiveCond
        (value: !(builtins.isAttrs value && value ? expr && value ? expected))
        (
          path: test:
          if test.expr == test.expected then
            true
          else
            throw "test ${nixpkgs.lib.concatStringsSep "." path} failed"
        )
        testSuites
      ) true;
    in
    {
      nixosModules = rec {
        dns = import ./modules/nixos.nix { inherit (self) utils; };
        default = dns;
      };
      utils = import ./utils { inherit (nixpkgs) lib; };
      lib =
        pkgs:
        import ./lib.nix {
          inherit pkgs;
          inherit (nixpkgs) lib;
          inherit (self) utils;
        };
      # __unfix__ and extend are filtered because of the fix point stuff. generate is filtered because it needs special architecture dependent treatment.
      tests = testSuites;
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bind
            glow
            mdbook
            nix-unit
            nixdoc
            statix
            nixfmt
          ];
        };
      });
      packages = eachSystem (pkgs: {
        docs = import ./docs {
          inherit (self) utils;
          inherit (pkgs) lib;
          inherit pkgs;
        };
        tests = pkgs.runCommand "nixos-dns-tests" { } ''
          ${if checkedTests then "true" else "false"}
          touch $out
        '';
      });
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      templates = {
        default = {
          path = ./example;
          description = "A simple Nix/OS dns example";
          welcomeText = ''
            A simple Nix/OS dns example
          '';
        };
      };
    };
}
