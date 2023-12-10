{
  description = "A flake providing Nix/OS dns utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs =
    { self
    , nixpkgs
    , flake-compat
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      nixosModules = rec {
        dns = import ./modules/nixos.nix { inherit (self) utils; };
        default = dns;
      };
      utils = import ./utils { inherit (nixpkgs) lib; };
      lib = pkgs:
        import ./lib.nix {
          inherit pkgs;
          inherit (nixpkgs) lib;
          inherit (self) utils;
        };
      # __unfix__ and extend are filtered because of the fix point stuff. generate is filtered because it needs special architecture dependent treatment.
      tests = nixpkgs.lib.mapAttrs (name: v: import "${./utils}/tests/${name}.nix" { inherit self; inherit (nixpkgs) lib; inherit (self) utils; }) (builtins.removeAttrs self.utils [ "__unfix__" "extend" "generate" ]);
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              bind
              glow
              mdbook
              nixpkgs-fmt
              nix-unit
              nixdoc
              statix
            ];
          };
        });
      packages = forAllSystems (system:
        {
          docs = import ./docs { inherit (self) utils; inherit (nixpkgs) lib; pkgs = nixpkgs.legacyPackages.${system}; };
        }
      );
      formatter = forAllSystems (
        system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
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
