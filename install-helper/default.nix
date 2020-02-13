let
  eval = import <nixpkgs/nixos> { configuration = ./configuration.nix; };
in eval.config
