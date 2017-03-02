let
  pkgs = import <nixpkgs> {};
  configuration = { ... }:
  {
    virtualisation.graphics = false;
    services.mingetty.autologinUser = "root";
  };
  eval = import <nixpkgs/nixos> { inherit configuration; };
in eval.vm
