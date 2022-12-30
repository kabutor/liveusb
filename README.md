# liveusb

![liveusb](https://github.com/kabutor/liveusb/raw/main/liveusb.png)

This project allows you to create a USB flash drive that work under UEFI firmwares even those with the Secure Boot on, this is a fork from https://github.com/alkisg/liveusb and it borrows a lot of the cfg files, hence this will be under the same license (GPL-3.0-or-later).
 
The main idea is that you this script will create a pendrive (or any external media device) that can hold different linux isos and boot from there.

## Linux instructions

To create the liveusb drive under Linux, run the efiliveusb.sh as root

```shell
sudo efiliveusb.sh
```
This will ask for the pendrive device (ie: */dev/sdb*) that is gonna be deleted, and then create a boot partition and a secondary partition (labeled ISOs) where you should place the iso you want to boot. 
**All the contents of that device will be deleted, be careful!!**

If you want to use debian just copy debian-live-11.6.0-amd64-cinnamon.iso into the debian directory in the ISOs partition.

At this moment this is only tested with debian, ubuntu and clonezilla, but you can edit grub.cfg to make others boot, bear in mind that if secure boot is enabled, only the distributions with a signed kernel will boot (that's a security requisite).

The files on the pendrive should be something like this

```
sdX1
├── EFI
│   └── BOOT
│       ├── bootx64.efi  # UEFI: Red Hat's signed by Microsoft bootloader, shimx64.efi
│       └── grubx64.efi  # Debian signed grubx64.efi
├── debian
│   └── grub.cfg  # The grub configuration file
│   └── grubenv  # grun enviroment file
sdX2
├── debian
|   └── (debian-live-11.6.0-amd64-cinnamon.iso this will not be created by the script, the isos you have to manually download and copy)
├── ubuntu
└── clonezilla

```
## Licenses
The files hosted here from another distribution are under their own licenses:
Grubx64.efi:
Files: debian/rules
Copyright: 2018 Philipp Matthias Hahn <pmhahn@debian.org>
License: GPL-2
Shimx64.efi:
Copyright: 2012 Red Hat, Inc
        2009-2012 Intel Corporation
License: BSD-2-Clause
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 .
 Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 .
 Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the
 distribution.
