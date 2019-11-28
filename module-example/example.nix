{ lib, ... }:

{
  options = {
    a = lib.mkOption {
      type = lib.types.listOf lib.types.int;
    };
  };
  config = lib.mkIf false {
    does.not.exist = true;
  };
}
