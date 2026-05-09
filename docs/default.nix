{
  lib,
  utils,
  pkgs,
}:
let
  format = pkgs.formats.toml { };
  prepareDocs = pkgs.runCommand "book" { } ''
    mkdir -p $out
    cp ${./book}/* $out/
    cp -R ${(pkgs.callPackage (import ./utils.nix { inherit utils; }) { })} $out/utils
    cp -R ${(pkgs.callPackage (import ./modules.nix { inherit utils; }) { })} $out/modules
  '';
  book = format.generate "book.toml" {
    book = {
      authors = [ "Janik H." ];
      language = "en";
      src = "${prepareDocs}";
      title = "NixOS-DNS";
    };
  };
in
pkgs.runCommand "docs" { } ''
  mkdir -p $out

  mkdir -p ./theme
  ln -s ${book} ./book.toml
  ${lib.getExe' pkgs.mdbook "mdbook"} build

  shopt -s dotglob
  mv book/* $out
''
