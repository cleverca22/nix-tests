{
  packageOverrides = pkgs: {
    stdenv = pkgs.stdenv // {
      mkDerivation = args: pkgs.stdenv.mkDerivation (args // {
        NIX_CFLAGS_COMPILE = (toString args.NIX_CFLAGS_COMPILE or "") + "-g";
      });
    };
  };
}