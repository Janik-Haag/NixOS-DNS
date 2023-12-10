{ lib }:
let
  utils = lib.makeExtensible (self:
    let
      callUtils = file: import file { inherit lib; utils = self; };
    in
    {
      debug = callUtils ./debug.nix;
      domains = callUtils ./domains.nix;
      general = callUtils ./general.nix;
      generate = callUtils ./generate.nix;
      helper = callUtils ./helper.nix;
      octodns = callUtils ./octodns.nix;
      # types = callUtils ./types.nix;
      zonefiles = callUtils ./zonefiles.nix;
    });
in
utils
