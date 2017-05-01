2017-05-01 13:50:58 < bachp> Is there an easy way to check if a NixOS update is available? I'm traing to write a small notification script that is running on my Machine and shows me a popup whenever a new version is available and nixos-rebuild switch would update the system. Kind of like the updata available indicator in other distributions.
2017-05-01 13:53:42 < clever> bachp: either check the revisions on https://github.com/NixOS/nixpkgs-channels or http://howoldis.herokuapp.com/
2017-05-01 13:53:54 < goibhniu> hi bachp, I've been working on something similar, perhaps you can re-use some code: https://github.com/cillianderoiste/NixTrayWidget
2017-05-01 13:53:56 < clever> which reminds me, i started something that did that over git, where did i leave it, lol
2017-05-01 13:54:21 < gchristensen> In Which Everyone Has Solved This Problem Different Ways
2017-05-01 13:54:25  * goibhniu uses JSON from howoldis
2017-05-01 13:54:49 < clever> -rw-r--r-- 1 clever users 3.5K Feb 29  2016 main.cpp
2017-05-01 13:54:57 < clever> found it, year old, not even in git
2017-05-01 13:55:03 < gchristensen> an on feb 29 even
2017-05-01 13:55:27 < clever> [clever@amd-nixos:~/apps/nix-tracker]$ ./nix-tracker
2017-05-01 13:55:27 < clever> bash: ./nix-tracker: No such file or directory
2017-05-01 13:55:31 < clever> and the ld.so got GC'd
2017-05-01 13:55:51 < gchristensen> bachp: you might find nixos-version's --hash option useful :)

