``virtualisation.virtualbox.guest.enable = true;`` in the configuration.nix for the tar and 
```
root@ubuntu:/sys/bus/pci/drivers/vboxvideo# ls -l
total 0
lrwxrwxrwx 1 root root    0 Dec 11 14:56 0000:00:02.0 -> ../../../../devices/pci0000:00/0000:00:02.0
root@ubuntu:/sys/bus/pci/drivers/vboxvideo# echo 0000\:00\:02.0 > unbind 
```
prior to kexec will allow the vboxvideo driver to recover and continue working in the new kernel after kexec
