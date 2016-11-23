with import <nixpkgs> {};

builtins.derivation {
  system = builtins.currentSystem;
  name = "bare-env";
  builder = stdenv.shell;
  args = [ (writeText "builder.sh" ''
    ${procps}/bin/ps -eH ux
    ${coreutils}/bin/env
    ${coreutils}/bin/id
    ${coreutils}/bin/cat /proc/mounts
  '') ];
}
