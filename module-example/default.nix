with import <nixpkgs> {};

pkgs.lib.evalModules {
  prefix = [];
  check = true;
  modules = [ ./example.nix ./expr.nix ];
  args = {};
}
