with import <nixpkgs> {};

rec {
    bar_h = builtins.filterSource (name: type: lib.hasSuffix "/bar.h" name) ./.;
    foo_headers = buildEnv {
      name = "foo_headers";
      paths = [ bar_h ];
    };
    foo = runCommandCC "foo.o" {} "gcc -c ${./foo.c} -I${foo_headers} -o $out";
    bar = runCommandCC "bar.o" {} "gcc -c ${./bar.c} -o $out";
    main = runCommandCC "main" {} "gcc ${foo} ${bar} -o $out";
}