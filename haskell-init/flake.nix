{
  outputs = { self, nixpkgs }:
  let
    pkgs = (import nixpkgs { system = "x86_64-linux"; });
  in {
    packages.x86_64-linux = pkgs.lib.fix (s: {
      ghc = pkgs.pkgsCross.musl64.haskellPackages.ghcWithPackages (p: with p; [ directory split transformers mtl linux-mount ] );
      hello_world = pkgs.stdenv.mkDerivation {
        name = "hello_world";
        nativeBuildInputs = with pkgs; [
          s.ghc
          #(import <nixpkgs>{}).llvm
          #(import <nixpkgs> {}).strace
        ];
        buildInputs = with pkgs; [ pkgs.libffi pkgs.gmp ];
        unpackPhase = ''
          cp ${./hello_world.hs} hello_world.hs
        '';
        installPhase = ''
          mkdir -p $out/bin
          #{pkgs.pkgsCross.musl64.ghc.targetPrefix}ghc
          x86_64-unknown-linux-musl-ghc hello_world.hs -static -split-sections -o $out/bin/init
          $STRIP $out/bin/init
        '';
      };
      hello_world' = pkgs.runCommand "hello_world2" {} ''cp ${s.hello_world}/bin/init $out'';
      initrd  = pkgs.makeInitrd {
        contents = [
          {
            object = s.hello_world';
            symlink = "/init";
          }
        ];
      };
      tester = pkgs.writeScript "tester" ''
        #!${pkgs.stdenv.shell}
        export PATH=${pkgs.coreutils}/bin/:${pkgs.utillinux}/bin/
        mount -v -t proc proc proc
        ls -l /proc/self/fd/
        #${pkgs.strace}/bin/strace -f ${s.hello_world}/bin/init
      '';
      kernel = pkgs.linuxPackages.kernel;
      script = pkgs.writeScriptBin "script" ''
      #!${pkgs.stdenv.shell}
      ${pkgs.qemu}/bin/qemu-system-x86_64 -kernel ${s.kernel}/bzImage -initrd ${s.initrd}/initrd -m 512 -append "console=ttyS0 quiet"
      #-nographic -serial mon:stdio
      '';
    });
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.script;
  };
}
