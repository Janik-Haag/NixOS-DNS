{ utils }:
{
  lib,
  fetchpatch,
  nixdoc,
  nixosOptionsDoc,
  runCommand,
  ...
}:
let
  utilNames = lib.mapAttrsToList (name: value: name) (
    builtins.removeAttrs utils [
      "__unfix__"
      "extend"
    ]
  );
in
runCommand "utils" { } ''
  mkdir -p $out
  cp ${./utils.md} $out/index.md
  ${lib.concatLines (
    builtins.map (
      name:
      "${lib.getExe' nixdoc "nixdoc"} --file ${../utils/${name}.nix} --prefix 'utils' --category '${name}' --description '${name}' > $out/${name}.md"
    ) utilNames
  )}
''
