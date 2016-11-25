{ pkgs }:

with pkgs.lib;

rec {
  forward_header = ''
    $TTL 3D
    @ IN SOA ns.localnet. hostmaster (1 8H 2H 4W 1D)
         NS ns.localnet.
  '';
  reverse_header = ''
    $TTL 3D
    @ IN SOA ns.localnet. hostmaster (1 8H 2H 4W 1D)
  '';
  create_forward = hosts: pkgs.writeText "dns.forward" (forward_header + (concatMapStringsSep "\n"
    (h:
      concatStringsSep "\n" (
        (optional (h ? v6) "${h.name} IN AAAA ${h.v6}") ++
        (optional (h ? v4) "${h.name} IN A ${h.v4}")
      )
    ) hosts));
  reverse-generator = pkgs.runCommandCC "reverse-generator" { buildInputs = [ pkgs.jsoncpp ]; } ''
    mkdir -p $out/bin
    g++ ${./reverse-generator.cpp} -o $out/bin/reverse-generator -Wall -ljsoncpp
  '';
  create_reverse = hosts: domain: pkgs.runCommand "dns.reverse" { buildInputs = [ reverse-generator ]; } ''
    cat ${pkgs.writeText "header.rev" reverse_header} > $out
    reverse-generator '${builtins.toJSON hosts}' ${domain} >> $out
  '';
}