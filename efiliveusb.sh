#!/bin/sh
#

set -e 

lsblk 2>/dev/null
echo "Type your pendrive unit (ex: /dev/sdg /dev/sdc not the partition)"
read usbdrive 2>/dev/tty

#copied from https://github.com/notthebee/macos_usb/blob/master/macos_usb.sh
usb="$(readlink /sys/block/$(echo ${usbdrive} | sed 's/^\/dev\///') | grep -o usb)"
if [ -z "$usb" ]; then
	echo "WARNING! ${flashdrive} is NOT a USB device"
	echo "Are you sure you know what you're doing?"
	read -p " [Y/N] " answer 2>/dev/tty
	if [[ ! $answer =~ ^[Yy]$ ]]; then
		echo "Abort"
		exit 0
	fi	
fi

boot_unit=${usbdrive}1
isos_unit=${usbdrive}2

echo "Making partitions on the pendrive"
parted $usbdrive <<EOF
mklabel gpt
mkpart primary fat32 1MiB 260MiB
set 1 esp on
mkpart primary ext3 261MiB 100%
quit
EOF

partprobe $usbdrive

echo "Formatting partitions"
sleep 3
#wait until kernel sees the partition
while [ ! -e $boot_unit ];do sleep 1;done

# used as a liveusb identifier, one is the boot partition the other is the isos partition
mkfs.fat -F32 -v -i $(date "+1973%y%m") -n LIVEUSB $boot_unit
mkfs.ext3 -L ISOs -U 56dae88c-82ec-11ed-bd74-c3d7a0c97a46 $isos_unit

temp_mnt="$(mktemp -d)"

mount $boot_unit $temp_mnt
# grub-install creates EFI/Boot directories, use lowercase in advance
mkdir -p ${temp_mnt}/efi/boot
#sudo grub-install --target=i386-pc --boot-directory=/tmp/liveusb /dev/loop5
#sudo grub-install --target=x86_64-efi --uefi-secure-boot --efi-directory=/tmp/liveusb --boot-directory=/tmp/liveusb /dev/loop5
grub-install --target=x86_64-efi --removable --efi-directory=$temp_mnt --boot-directory=$temp_mnt 
mkdir ${temp_mnt}/efi/debian
cp --preserve=timestamps grub_efi.cfg ${temp_mnt}/efi/debian/grub.cfg
#sudo mkdir /tmp/liveusb/liveusb
#sudo mount /dev/loop5p2 /tmp/liveusb/liveusb
cp shimx64.efi ${temp_mnt}/efi/boot/bootx64.efi
cp grubx64.efi.signed ${temp_mnt}/efi/boot/grubx64.efi
cp grubenv ${temp_mnt}/efi/debian/
cd $temp_mnt
#sudo mkdir -p clonezilla debian efi fedora kali linux16 manjaro memdisk opensuse ubuntu
# Ordered by target name
wget -nv "https://boot.ipxe.org/ipxe.efi" -O efi/ipxe.efi
wget -nv "https://github.com/tianocore/edk/raw/master/Other/Maintained/Application/UefiShell/bin/x64/Shell.efi" -O efi/shellx64.efi

cd -
umount $temp_mnt 

mount $isos_unit $temp_mnt
mkdir -p ${temp_mnt}/ubuntu ${temp_mnt}/debian ${temp_mnt}/clonezilla
umount $temp_mnt
rmdir $temp_mnt
echo "Success"
