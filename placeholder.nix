with import <nixpkgs> {}; runCommand "name" {} "echo ${builtins.placeholder "out"} > $out"
