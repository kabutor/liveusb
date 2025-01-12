# liveusb

![liveusb](https://github.com/kabutor/liveusb/raw/main/liveusb.png)

This project allows you to create a USB flash drive that work under UEFI firmwares main focus is to be bootable on those with the **Secure Boot** on, but it should work with the secure boot off as well. 
This is a fork from https://github.com/alkisg/liveusb and it borrows a lot of the cfg files, hence this will be under the same license (GPL-3.0-or-later).
 
The main idea is that you this script will create a pendrive (or any external media device) that can hold a linux iso and boot from there, initially I was able to boot debian or uvuntu, as long as the kernel was signed (more on this below), but I just discover that the whle boot sequence has to be signed with the same provider (more on this below) so now the main focus is to make this bootable using a Ubuntu live cd, but you can use it for debian, just change the variable at the top of the script distribution="debian" if you want to use a debian signed kernel.

## Linux instructions

To create the liveusb drive under Linux, clone the repository and run the efiliveusb.sh as root. You can change the line at the beggining that contains distribution="ubuntu" and change it to "debian" if you plan to use it instead of ubuntu

```shell
sudo sh efiliveusb.sh
```

This will ask for the pendrive device (ie: */dev/sdb*) that is gonna be deleted, and then create a boot partition and a secondary partition (labeled ISOs) where you should place the iso you want to boot. 
**All the contents of that device will be deleted, be careful!!**

The mount the second partition called "ISOs" and copy the Ubuntu iso live cd (ubuntu-22.04.1-desktop-amd64.iso) into the ubuntu folder. If you want to use debian just copy debian-live-11.6.0-amd64-cinnamon.iso into the debian directory in the ISOs partition.

At this moment this is only tested with ubuntu, debian and clonezilla (you should use the debian option in the first line of the sh file as clonezilla is a derived version of debian), but you can edit grub.cfg to make others boot, bear in mind that if secure boot is enabled, only the distributions with a signed kernel will boot (that's a security requisite). More about this below.

The files on the pendrive should be something like this

```
sdX1
├── EFI
│   └── BOOT
│       ├── bootx64.efi  # UEFI: Red Hat's signed by Microsoft bootloader, shimx64.efi
│       └── grubx64.efi  # Ubuntu/Debian signed grubx64.efi
├── ubuntu or debian
│   └── grub.cfg  # The grub configuration file
│   └── grubenv  # grun enviroment file
sdX2
├── debian
|   └── (debian-live-11.6.0-amd64-cinnamon.iso this will not be created by the script, the isos you have to manually download and copy)
├── ubuntu
|   └── (ubuntu-22.04.1-desktop-amd64.iso this will not be created by the script, the isos you have to manually download and copy)
└── clonezilla

```
## EFI Secure Boot

Some theory about secure boot, the way it works (AFAIK) a signed efi file is needed in order to boot the computer, the shimx64.efi was signed by Microsoft and it's the first thing needed to boot. Also shimx64.efi are signed by each distribution, canonical or debian. While testing I can say that with old more laxes UEFIs it doesn't matter the shim you are using, on more modern, more robust UEFIs you need the shim of the distribution you are booting, as those are also signed by them.
Then it passes to the grubx64.efi, that needs to be signed as well, you can use sbverify from sbsigntools to check the signature.
In this repo I am using the next files:

```
(the shim signature is the same but not the internal certificate)


$ sbverify --list shimx64_{debian/ubuntu}.efi 
warning: data remaining[809336 vs 934240]: gaps between PE/COFF sections?
signature 1
image signature issuers:
 - /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
image signature certificates:
 - subject: /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Windows UEFI Driver Publisher
   issuer:  /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
 - subject: /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation UEFI CA 2011
   issuer:  /C=US/ST=Washington/L=Redmond/O=Microsoft Corporation/CN=Microsoft Corporation Third Party Marketplace Root
  
   
$─# sbverify --list grubx64.efi.ubuntu.signed 
signature 1
image signature issuers:
 - /C=GB/ST=Isle of Man/L=Douglas/O=Canonical Ltd./CN=Canonical Ltd. Master Certificate Authority
image signature certificates:
 - subject: /C=GB/ST=Isle of Man/O=Canonical Ltd./OU=Secure Boot/CN=Canonical Ltd. Secure Boot Signing (2021 v1)
   issuer:  /C=GB/ST=Isle of Man/L=Douglas/O=Canonical Ltd./CN=Canonical Ltd. Master Certificate Authority

$ sbverify --list grubx64.efi.debian.signed
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

This works, and in some cases you can mix a ubuntu kernel with a debian signed grubx64.efi, but I realized that in some cases you can't, all the boot chain has to signed by the same, I guess some old flaky UEFI misbehave and are more forgiven abouth the whole chain boot load. Best option, and the one that always works is both kernel and grub to be signed from the same certificate authority. 

At this moment I'm wondering if I can create my own certificate and sign both grub and a kernel, for the moment my attempts to self-sign a Kali haven't worked, maybe I'm doing something wrong, or I need to have have some root certificate I don't have.

I'm doing for me a Live Ubuntu CD Custom following this guide, and it's booting (https://help.ubuntu.com/community/LiveCDCustomization), as long as you supply a signed kernel, or use the one that cames with the livecd, the rest of the contents doesn't matter.

Love to have some answers, but the documentation about the subject is a bit scarce, hence this section. If you want to try different distributions, first mount the live iso and check if the kernel is signed, if it's not signed, computer will not boot (unless you disable secure boot, that is out of the scope of this repo)


## Versions
v3 - Using the shim of each distribution
v2 - Changed to default Ubuntu

v1 - Initial version, tested, but probably some bugs here and there (20221230)

## Licenses

The files hosted here from another distribution are under their own licenses:


Grubx64.ubuntu.efi:
Upstream-Name: GNU GRUB
Source: http://www.gnu.org/software/grub/
Comment:
 This package exists to download a signed binary from the Ubuntu archive and
 publish it in .deb format.  The actual bootloader source code may be found
 in the grub2 source package: 'apt-get source grub2'.
Files: *
Copyright: 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009  Free Software Foundation, Inc
License: GPL-3+
Grubx64.debian.efi:
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

Shim canonical downloaded from https://launchpad.net/ubuntu/+source/shim-signed/1.51
