#!/bin/sh
# v3 script version
# change to debian if you want to use a debian distribution
distribution="ubuntu"

lsblk 2>/dev/null
echo "Type your pendrive unit (ex: /dev/sdg /dev/sdc not the partition)"
read usbdrive 2>/dev/tty

#copied from https://github.com/notthebee/macos_usb/blob/master/macos_usb.sh
usb="$(readlink /sys/block/$(echo ${usbdrive} | sed 's/^\/dev\///') | grep -o usb)"
if [ -z "$usb" ]; then
	echo "WARNING! ${usbdrive} is NOT a USB device"
	echo "Are you sure you know what you're doing?"
	read -p " [y/n] " answer 
	if [ ! $answer = "y" ]; then
		echo "Abort"
		exit 0
	fi	
fi


echo "Are you sure you want to delete ${usbdrive}? All data will be lost "
read -p " [y/n] " ans
if [ ! "$ans" = "y" ]; then
	echo "Abort"
	exit 0
fi

boot_unit=${usbdrive}1
isos_unit=${usbdrive}2

umount ${usbdrive}*

#abort if error from here on
set -e 

sgdisk --zap-all ${usbdrive}

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
grub-install --target=x86_64-efi --removable --efi-directory=$temp_mnt --boot-directory=$temp_mnt 
mkdir ${temp_mnt}/efi/${distribution}
cp --preserve=timestamps grub_efi.cfg ${temp_mnt}/efi/${distribution}/grub.cfg

cp shimx64_${distribution}.efi ${temp_mnt}/efi/boot/bootx64.efi
cp grubx64.efi.${distribution}.signed ${temp_mnt}/efi/boot/grubx64.efi
cp grubenv ${temp_mnt}/efi/${distribution}/

wget -nv "https://boot.ipxe.org/ipxe.efi" -O ${temp_mnt}/efi/ipxe.efi
wget -nv "https://github.com/tianocore/edk/raw/master/Other/Maintained/Application/UefiShell/bin/x64/Shell.efi" -O ${temp_mnt}/efi/shellx64.efi

umount $temp_mnt 

mount $isos_unit $temp_mnt
mkdir -p ${temp_mnt}/ubuntu ${temp_mnt}/${distribution} ${temp_mnt}/clonezilla
umount $temp_mnt
rmdir $temp_mnt
echo "Success"
