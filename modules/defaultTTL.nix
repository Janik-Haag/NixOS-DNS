# We do this because the option is needed by multiple modules
{ lib }:
lib.mkOption {
  description = lib.mdDoc ''
    this ttl will be applied to any record not explicitly having one set.
  '';
  default = 3600;
  type = lib.types.nullOr lib.types.int;
  internal = true;
}
