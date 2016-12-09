```
$ nix-build '<nixpkgs/nixos>' -A config.system.build.kexec_tarball -I nixos-config=./configuration.nix -Q -j 4 
$ scp result/tarball/nixos-system-x86_64-linux.tar.xz 192.168.2.151:.
$ ssh 192.168.2.151
Welcome to Ubuntu 16.10 (GNU/Linux 4.8.0-22-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

49 packages can be updated.
29 updates are security updates.

clever@ubuntu:~$ sudo -i
[sudo] password for clever:
root@ubuntu:~# cd /
root@ubuntu:/# tar -xf /home/clever/nixos-system-x86_64-linux.tar.xz
root@ubuntu:/# ./kexec_nixos 
executing kernel, filesystems will be improperly umounted
Connection to 192.168.2.151 closed.
[clever@amd-nixos:~/nix-tests/kexec]$ ping 192.168.2.151
PING 192.168.2.151 (192.168.2.151) 56(84) bytes of data.
64 bytes from 192.168.2.151: icmp_seq=1 ttl=64 time=0.197 ms
64 bytes from 192.168.2.151: icmp_seq=2 ttl=64 time=0.121 ms
64 bytes from 192.168.2.151: icmp_seq=3 ttl=64 time=0.181 ms
^C
[clever@amd-nixos:~/nix-tests/kexec]$ ssh root@192.168.2.151
The authenticity of host '192.168.2.151 (192.168.2.151)' can't be established.
ED25519 key fingerprint is SHA256:o1Tl49CuK6Ipd5gT6GaNfotsgVMJcdxr2FZbGrmhqmE.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.2.151' (ED25519) to the list of known hosts.
Last login: Fri Dec  9 05:47:11 2016

[root@kexec:~]# 
```
