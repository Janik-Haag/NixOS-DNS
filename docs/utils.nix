{ utils }: { lib
           , fetchpatch
           , nixdoc
           , nixosOptionsDoc
           , runCommand
           , ...
           }:
let
  utilNames = lib.mapAttrsToList (name: value: name) (builtins.removeAttrs utils [ "__unfix__" "extend" ]);
  patchedNixdoc = nixdoc.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [
      (fetchpatch {
        url = "https://github.com/nix-community/nixdoc/commit/b4480a2143464d8238402514dd35c78b6f9b9928.patch";
        hash = "sha256-WZ/tA2q+u4h7G1gUn2nkAutsjYHNxqXwjqAKpxYTf7k=";
      })
    ];
  });
in
runCommand "utils" { } ''
  mkdir -p $out
  cp ${./utils.md} $out/index.md
  ${
    lib.concatLines (builtins.map (name: "${lib.getExe' patchedNixdoc "nixdoc"} --file ${../utils/${name}.nix} --prefix 'utils' --category '${name}' --description '${name}' > $out/${name}.md") utilNames)
  }
''
