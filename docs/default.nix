{ lib, utils, pkgs }:
# docs = pkgs.callPackage ./docs.nix { };
let
  # can be removed once https://github.com/rust-lang/mdBook/pull/2262 lands
  highlight = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rust-lang/mdBook/7b9bd5049ce15ae5f301d5a40c50ce8359d9e9a8/src/theme/highlight.js";
    hash = "sha256-pLP73zlmGkbC/zV6bwnB6ijRf9gVkj5/VYMGLhiQ1/Q=";
  };
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
      multilingual = false;
      src = "${prepareDocs}";
      title = "NixOS-DNS";
    };
  };
in
pkgs.runCommand "docs" { } ''
  mkdir -p $out

  mkdir -p ./theme
  ln -s ${highlight} ./theme/highlight.js
  ln -s ${book} ./book.toml
  ${lib.getExe' pkgs.mdbook "mdbook"} build

  shopt -s dotglob
  mv book/* $out
''
