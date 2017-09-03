let
  pkgs = import <nixpkgs> {};
  ghc = pkgs.haskellPackages.ghcWithPackages (p: with p; [ directory split transformers mtl linux-mount ] );
  hello_world = pkgs.stdenv.mkDerivation {
    name = "hello_world";
    buildInputs = with pkgs; [ ghc ];
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      ghc ${./hello_world.hs} -static -split-sections -o $out/bin/init
    '';
  };
  hello_world' = pkgs.runCommand "hello_world2" {} ''cp ${hello_world}/bin/init $out'';
  tester = pkgs.writeScript "tester" ''
    #!${pkgs.stdenv.shell}
    export PATH=${pkgs.coreutils}/bin/:${pkgs.utillinux}/bin/
    mount -v -t proc proc proc
    ls -l /proc/self/fd/
    #${pkgs.strace}/bin/strace -f ${hello_world}/bin/init
  '';
  initrd  = pkgs.makeInitrd {
    contents = [
      {
        object = hello_world';
        symlink = "/init";
      }
    ];
  };
  kernel = pkgs.linuxPackages.kernel;
  script = pkgs.writeScriptBin "script" ''
  #!${pkgs.stdenv.shell}
  ${pkgs.qemu}/bin/qemu-system-x86_64 -kernel ${kernel}/bzImage -initrd ${initrd}/initrd -m 512 -append "console=ttyS0 quiet" -nographic -serial mon:stdio
  '';
in {
  inherit hello_world initrd kernel script tester;
}
