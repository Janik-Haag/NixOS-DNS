{ utils }:
{
  lib,
  runCommand,
  nixosOptionsDoc,
  ...
}:
let
  mkModuleDocs =
    module:
    (nixosOptionsDoc {
      inherit
        (lib.evalModules {
          modules = [
            # ignores the configs part in modules
            # which is good since we only want the options
            {
              config._module.check = false;
              options._module.args = lib.mkOption { visible = false; };
            }

            module
          ];
          specialArgs = {
            inherit utils;
          };
        })
        options
        ;
    }).optionsCommonMark;
  modules = {
    dnsConfig = import ../modules/dnsConfig.nix;
    extraConfig = import ../modules/extraConfig.nix;

    nixos = import ../modules/nixos.nix { inherit utils; };
    # darwin = import ../modules/darwin.nix { inherit utils; };
  };
in
runCommand "modules" { } ''
  mkdir -p $out
  cp ${./modules.md} $out/index.md
  ${lib.concatLines (
    lib.mapAttrsToList (name: module: "cat ${mkModuleDocs module} > $out/${name}.md") modules
  )}
''
