#!/bin/bash
apt-get update
apt-get install --force-yes --yes nano
apt-get install --force-yes --yes rsync
apt-get install --force-yes --yes debootstrap
fallocate -l 1500M debian.img
echo -e "o\nn\np\n1\n\n\nw" |  fdisk debian.img
echo -e "a\nw\n" |  fdisk debian.img
LO_DEVICE=$( echo $(losetup --partscan --show --find debian.img))
LO_PART1=${LO_DEVICE}p1
CF_FILE1=$(cat add.sh)
mkfs.ext4 ${LO_PART1}
mkdir -p /mnt/debian
mount ${LO_PART1} /mnt/debian
ln -s /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/artful
ln -s /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/bionic
ln -s /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/cosmic
debootstrap --arch=amd64 --variant=minbase bionic /mnt/debian http://de.archive.ubuntu.com/ubuntu
mount -t proc /proc /mnt/debian/proc
mount -t sysfs /sys /mnt/debian/sys
mount -o bind /dev /mnt/debian/dev
cp ./udevrules.tar /mnt/debian
chmod 777 /mnt/debian/udevrules.tar
cat << EOF |  chroot /mnt/debian
apt-get update
apt-get install --no-install-recommends --force-yes --yes systemd-sysv
apt-get install --no-install-recommends --force-yes --yes linux-image-generic
apt-get install --no-install-recommends --force-yes --yes udev
apt-get install --no-install-recommends --force-yes --yes libblkid1
apt-get install --no-install-recommends --force-yes --yes usbmount
apt-get install --no-install-recommends --force-yes --yes initramfs-tools
dd bs=512 count=1 if=/dev/sda of=./mbr_backup.img
echo -e '1\n' | apt-get install --no-install-recommends --force-yes --yes grub2-common grub-pc
echo 'LABEL=DEBUSB / ext4 defaults 0 1' > /etc/fstab
grub-install --target=i386-pc --boot-directory=/boot --force-file-id --skip-fs-probe --recheck ${LO_DEVICE}
#Your Configuration
echo -e '\n\n\n\n\n\n\n\n\n\n\n\n\n\n' | apt-get install --no-install-recommends --force-yes --yes locales
locale-gen --purge de_DE.UTF-8
echo -e 'LC_ALL="de_DE.UTF-8"\nLANG="de_DE.UTF-8"\nLANGUAGE="de_DE:de"\n' > /etc/default/locale
LC_ALL="de_DE.UTF-8"
LANG="de_DE.UTF-8"
LANGUAGE="de_DE:de"
export $LC_ALL
export $LANG
export $LANGUAGE
export LC_ALL=$LC_ALL
export LANG=$LANG
export LANGUAGE=$LANGUAGE
localectl set-locale LC_MESSAGES=de_DE.utf8 LANG=de_DE.UTF-8
update-locale
echo -e '\n\n\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n' | apt-get install --no-install-recommends --force-yes --yes  keyboard-configuration console-setup console-data
localectl set-keymap --no-convert de
loadkeys de
apt-get install --no-install-recommends --force-yes --yes nano
apt-get install --no-install-recommends --force-yes --yes vim
apt-get install --no-install-recommends --force-yes --yes git
apt-get install --no-install-recommends --force-yes --yes perl
apt-get install --no-install-recommends --force-yes --yes openssh-server
apt-get install --no-install-recommends --force-yes --yes openssh-client
apt-get install --no-install-recommends --force-yes --yes openssh-server
apt-get install --no-install-recommends --force-yes --yes ncftp
apt-get install --no-install-recommends --force-yes --yes network-manager
apt-get install --no-install-recommends --force-yes --yes lsb-release
echo -e 'root\nroot\n' | passwd root
adduser --quiet --system --group --disabled-password --shell /bin/bash --home /home/debian --gecos "Full name,Room number,Work phone,Home phone" debian
echo -e 'debian\ndebian\n' | passwd debian
adduser debian
echo -e '\n\n\nset default="0"\nset timeout=10\nmenuentry "Debian" {\n    linux /vmlinuz root=/dev/disk/by-label/DEBUSB quiet\n    initrd /initrd.img\n}\n\n\n' >> /etc/grub.d/40_custom
echo 'GRUB_DISABLE_LINUX_UUID=true' >> /etc/default/grub
echo 'GRUB_ENABLE_LINUX_LABEL=true' >> /etc/default/grub
update-grub
apt-get install --no-install-recommends --force-yes --yes parted
apt-get install --no-install-recommends --force-yes --yes gnupg
apt-get install --no-install-recommends --force-yes --yes ca-certificates
e2label ${LO_PART1} DEBUSB
echo -e '#!/bin/bash\nmount -t proc proc proc/\nmount -t sysfs sys sys/\nmount -o bind /dev dev/' > /chrootme.sh
echo -e '#!/bin/bash\numount ./{dev,sys,proc}\numount .\n' > /unchrootme.sh
chmod 755 /chrootme.sh
chown root:root /chrootme.sh
chmod 755 /unchrootme.sh
chown root:root /unchrootme.sh
echo 'LABEL=DEBUSB / ext4 rw,suid,dev,exec,auto,nouser,async,errors=continue 0 1' > /etc/fstab
# echo 'proc /proc proc rw,suid,dev,exec,auto,nouser,async,errors=continue 0 0' >> /etc/fstab
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4052245BD4284CDD
echo "deb https://repo.iovisor.org/apt/bionic bionic main" | tee /etc/apt/sources.list.d/iovisor.list
apt-get update
apt-get install --no-install-recommends --force-yes --yes bcc-tools
apt-get install --no-install-recommends --force-yes --yes libbcc-examples
apt-get install --no-install-recommends --force-yes --yes linux-headers-generic
dd bs=512 count=1 if=./mbr_backup.img of=/dev/sda
echo ${CF_FILE1} |  awk '{system($0)}'
cd / && tar xvf udevrules.tar
rm udevrules.tar
exit
EOF
umount /mnt/debian/{dev,sys,proc}
umount /mnt/debian
losetup -d ${LO_DEVICE}
if [ $# -gt 0 ]; then
    dd if=/dev/zero bs=1MiB of=${LO_DEVICE} conv=notrunc oflag=append count=$1
    resize2fs ${LO_DEVICE}
    e2label ${LO_DEVICE} DEBUSB
fi
