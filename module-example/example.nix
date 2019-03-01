{ lib, ... }:

{
  options = {
    a = lib.mkOption {
      type = lib.types.listOf lib.types.int;
    };
  };
  config = {};
}
