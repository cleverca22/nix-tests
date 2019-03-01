```
[clever@amd-nixos:~/nix-tests/module-example]$ nix repl default.nix
Welcome to Nix version 2.2. Type :? for help.

Loading 'default.nix'...
Added 2 variables.

nix-repl> config.a
[ 2 1 ]
```
`example.nix` defines a to be an option, that is a list of ints, and then `exrp.nix` and `expr2.nix` set a to different things, [1] and [2], `default.nix` then merges all 3 files together, and looks at `config.a`
