#!/bin/bash
apt-get update && apt-get install sudo nano --force-yes --yes
sudo apt-get install debootstrap
fallocate -l 1G debian.img
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk debian.img
echo -e "a\nw\n" | sudo fdisk debian.img
LO_DEVICE=$(echo $(losetup --partscan --show --find debian.img))
LO_PART1=${LO_DEVICE}p1
sudo mkfs.ext4 ${LO_PART1}
sudo mkdir -p /mnt/debian
sudo mount ${LO_PART1} /mnt/debian
sudo debootstrap --arch=i386 --variant=minbase stretch /mnt/debian http://ftp.us.debian.org/debian/
sudo mount -t proc /proc /mnt/debian/proc
sudo mount -t sysfs /sys /mnt/debian/sys
sudo mount -o bind /dev /mnt/debian/dev
cat << EOF | sudo chroot /mnt/debian
apt-get update
echo -e "a\nyes\n" | apt-get install --no-install-recommends --force-yes --yes linux-image-586 systemd-sysv grub2-common grub-pc && echo "LABEL=DEBUSB / ext4 defaults 0 1" > /etc/fstab
grub-install --target=i386-pc --boot-directory=/boot --force-file-id --skip-fs-probe --recheck ${LO_DEVICE}
#Your Configuration
apt-get install --no-install-recommends --force-yes --yes sudo nano vim git perl openssh-server openssh-client ncftp network-manager
echo -e "root\nroot\n" | passwd root
adduser --quiet --system --group --disabled-password --shell /bin/bash --home /home/debian --gecos "Full name,Room number,Work phone,Home phone" debian
echo -e "debian\ndebian\n" | passwd debian
adduser debian sudo
echo -e '\n\n\nset default="0"\nset timeout=10\nmenuentry "Debian" {\n    linux /vmlinuz root=/dev/disk/by-label/DEBUSB quiet\n    initrd /initrd.img\n}\n\n\n' >> /etc/grub.d/40_custom
update-grub
exit
EOF
