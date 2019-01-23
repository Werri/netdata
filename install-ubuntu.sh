#!/bin/bash
apt-get update && apt-get install sudo nano --force-yes --yes
sudo apt-get update && sudo apt-get install sudo nano --force-yes --yes
sudo apt-get install debootstrap
sudo fallocate -l 1G debian.img
sudo echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk debian.img
sudo echo -e "a\nw\n" | sudo fdisk debian.img
LO_DEVICE=$(sudo echo $(sudo losetup --partscan --show --find debian.img))
LO_PART1=${LO_DEVICE}p1
CF_FILE1=$(cat add.sh)
sudo mkfs.ext4 ${LO_PART1}
sudo mkdir -p /mnt/debian
sudo mount ${LO_PART1} /mnt/debian
sudo debootstrap --arch=amd64 --variant=minbase xenial /mnt/debian http://de.archive.ubuntu.com/ubuntu
sudo mount -t proc /proc /mnt/debian/proc
sudo mount -t sysfs /sys /mnt/debian/sys
sudo mount -o bind /dev /mnt/debian/dev
sudo cat << EOF | sudo chroot /mnt/debian
apt-get update
apt-get install --no-install-recommends --force-yes --yes linux-image-amd64 systemd-sysv sudo
sudo apt-get update
sudo apt-get install --no-install-recommends --force-yes --yes linux-image-amd64 systemd-sysv sudo
sudo dd bs=512 count=1 if=/dev/sda of=./mbr_backup.img
sudo echo -e "1\n" | sudo apt-get install --no-install-recommends --force-yes --yes grub2-common grub-pc
sudo echo "LABEL=DEBUSB / ext4 defaults 0 1" > /etc/fstab
sudo grub-install --target=i386-pc --boot-directory=/boot --force-file-id --skip-fs-probe --recheck ${LO_DEVICE}
#Your Configuration
sudo echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n" | sudo apt-get install --no-install-recommends --force-yes --yes locales
sudo locale-gen --purge de_DE.UTF-8
sudo echo -e 'LC_ALL="de_DE.UTF-8"\nLANG="de_DE.UTF-8"\nLANGUAGE="de_DE:de"\n' > /etc/default/locale
LC_ALL="de_DE.UTF-8"
LANG="de_DE.UTF-8"
LANGUAGE="de_DE:de"
export $LC_ALL
export $LANG
export $LANGUAGE
export LC_ALL=$LC_ALL
export LANG=$LANG
export LANGUAGE=$LANGUAGE
sudo localectl set-locale LC_MESSAGES=de_DE.utf8 LANG=de_DE.UTF-8
sudo update-locale
sudo echo -e '\n\n\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n2\n' | sudo apt-get install --no-install-recommends --force-yes --yes  keyboard-configuration console-setup console-data
sudo localectl set-keymap --no-convert de
sudo loadkeys de
sudo apt-get install --no-install-recommends --force-yes --yes sudo nano vim git perl openssh-server openssh-client ncftp network-manager
sudo echo -e "root\nroot\n" | passwd root
sudo adduser --quiet --system --group --disabled-password --shell /bin/bash --home /home/debian --gecos "Full name,Room number,Work phone,Home phone" debian
sudo echo -e "debian\ndebian\n" | passwd debian
sudo adduser debian sudo
sudo echo -e '\n\n\nset default="0"\nset timeout=10\nmenuentry "Debian" {\n    linux /vmlinuz root=/dev/disk/by-label/DEBUSB quiet\n    initrd /initrd.img\n}\n\n\n' >> /etc/grub.d/40_custom
sudo echo 'GRUB_DISABLE_LINUX_UUID=true' >> /etc/default/grub
sudo echo 'GRUB_ENABLE_LINUX_LABEL=true' >> /etc/default/grub
sudo update-grub
sudo apt-get install --no-install-recommends --force-yes --yes parted
sudo e2label ${LO_DEVICE} DEBUSB
sudo echo -e "#!/bin/bash\nmount -t proc proc proc/\nmount -t sysfs sys sys/\nmount -o bind /dev dev/" > /chrootme.sh
sudo echo -e "#!/bin/bash\nexit\numount ./{dev,sys,proc}\numount .\n" > /unchrootme.sh
sudo chmod 755 /chrootme.sh
sudo chown root:root /chrootme.sh
sudo chmod 755 /unchrootme.sh
sudo chown root:root /unchrootme.sh
sudo echo "LABEL=DEBUSB / ext4 rw,suid,dev,exec,auto,nouser,async,errors=continue 0 1" > /etc/fstab
#sudo echo "proc /proc proc rw,suid,dev,exec,auto,nouser,async,errors=continue 0 0" >> /etc/fstab
sudo dd bs=512 count=1 if=./mbr_backup.img of=/dev/sda
sudo echo ${CF_FILE1} |sudo  awk '{system($0)}'
sudo exit
EOF
sudo umount /mnt/debian/{dev,sys,proc}
sudo umount /mnt/debian
sudo losetup -d ${LO_DEVICE}
if [ $# -gt 0 ]; then
   sudo dd if=/dev/zero bs=1MiB of=${LO_DEVICE} conv=notrunc oflag=append count=$1
   sudo resize2fs ${LO_DEVICE}
   sudo e2label ${LO_DEVICE} DEBUSB
fi
