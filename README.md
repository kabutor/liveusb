# liveusb

![liveusb](https://github.com/kabutor/liveusb/raw/main/liveusb.png)

This project allows you to create a USB flash drive that work under UEFI firmwares even those with the **Secure Boot** on, this is a fork from https://github.com/alkisg/liveusb and it borrows a lot of the cfg files, hence this will be under the same license (GPL-3.0-or-later).
 
The main idea is that you this script will create a pendrive (or any external media device) that can hold different linux isos and boot from there.

## Linux instructions

To create the liveusb drive under Linux, run the efiliveusb.sh as root

```shell
sudo efiliveusb.sh
```
This will ask for the pendrive device (ie: */dev/sdb*) that is gonna be deleted, and then create a boot partition and a secondary partition (labeled ISOs) where you should place the iso you want to boot. 
**All the contents of that device will be deleted, be careful!!**

If you want to use debian just copy debian-live-11.6.0-amd64-cinnamon.iso into the debian directory in the ISOs partition.

At this moment this is only tested with debian, ubuntu and clonezilla, but you can edit grub.cfg to make others boot, bear in mind that if secure boot is enabled, only the distributions with a signed kernel will boot (that's a security requisite). More about this below.

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
## EFI Secure Boot

Some theory about secure boot, the way it works (AFAIK) a signed efi file is needed in order to boot the computer, the shimx64.efi was signed by Microsoft and it's the first thing needed to boot. Then it passes to the grubx64.efi, that needs to be signed as well, you can use sbverify from sbsigntools to check the signature.

```
$ sbverify --list shimx64.efi 
warning: data remaining[809336 vs 934240]: gaps between PE/COFF sections?
signature 1
image signature issuers:
 - /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
image signature certificates:
 - subject: /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Windows UEFI Driver Publisher
   issuer:  /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
 - subject: /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
   issuer:  /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation Third Party Marketplace Root
   
$ sbverify --list grubx64.efi 
signature 1
image signature issuers:
 - /CN=Debian Secure Boot CA
image signature certificates:
 - subject: /CN=Debian Secure Boot Signer 2022 - grub2
   issuer:  /CN=Debian Secure Boot CA

```

Then it reads the grub.cfg (it has to be in efi/debian) and boots, the booting kernel need to be signed, and the external modules that it loads. Here as an example the ubuntu kernel from the livecd version (22.04.1)
```
$ sbverify --list vmlinuz 
signature 1
image signature issuers:
 - /C=GB/ST=Isle of Man/L=Douglas/O=Canonical Ltd./CN=Canonical Ltd. Master Certificate Authority
image signature certificates:
 - subject: /C=GB/ST=Isle of Man/O=Canonical Ltd./OU=Secure Boot/CN=Canonical Ltd. Secure Boot Signing (2017)
   issuer:  /C=GB/ST=Isle of Man/L=Douglas/O=Canonical Ltd./CN=Canonical Ltd. Master Certificate Authority
```

This works, and I don't really know why, grubx64 is signed by Debian, but the Ubuntu kernel is signed by Canonical, and it works, and it didn't make any sense. I don't know if there is some vault with the allowed list of signers, or my attempts to self-sign a Kali kernel were badly done, but I can only boot signed kernels, the ones I tried from Debian or Canonical (clonezilla livecd has a debian signed kernel) works. I'm even doing a Live Ubuntu CD Custom following this guide, and it's booting (https://help.ubuntu.com/community/LiveCDCustomization), as long as you supply a signed kernel the rest of the contents doesn't matter.

Love to have some answers, but the documentation about the subject is a bit scarce, hence this section. If you want to try different distributions, first mount the live iso and check if the kernel is signed, if it's not signed, computer will not boot (unless you disable secure boot, that is out of the scope of this repo)


## Versions
v1 - Initial version, tested, but probably some bugs here and there (20221230)

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
