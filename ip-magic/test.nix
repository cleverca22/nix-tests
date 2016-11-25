with import <nixpkgs> {};

rec {
  core = import ./core.nix { inherit pkgs; };
  sample_hosts = [
    { name="host1"; mac="11:22:33:44:55:66"; v4 = "192.168.3.10"; v6 = "2001:db8:85a3::8a2e:370:7334"; }
    { name="host2"; mac="11:22:33:44:55:77"; v4 = "192.168.3.11"; v6 = "2001:db8:85a3::8a2e:370:7335"; }
    { name="host3"; mac="11:22:33:44:55:88"; v4 = "192.168.3.12"; }
    { name="host4"; mac="11:22:33:44:55:99"; v6 = "2001:db8:85a3::8a2e:370:7336"; }
  ];
  dns.forward = core.create_forward sample_hosts;
  dns.reverse = core.create_reverse sample_hosts "localnet.";
}