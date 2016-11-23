with import <nixpkgs> {};

builtins.derivation {
  system = builtins.currentSystem;
  name = "bare-env";
  builder = stdenv.shell;
  args = [ (writeText "builder.sh" ''
    ${coreutils}/bin/env
  '') ];
}