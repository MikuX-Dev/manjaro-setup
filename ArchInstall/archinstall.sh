#!/bin/bash

# Check for UEFI mode
if [ ! -d /sys/firmware/efi/efivars ]; then
    echo "ERROR: UEFI mode not detected. Please boot into UEFI mode and try again."
    exit 1
fi

# Enable network time synchronization
timedatectl set-ntp true

# Set timezone to Asia/Kolkata
timedatectl set-timezone Asia/Kolkata

# Partition the disk
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary ext4 1MiB 798GiB
parted /dev/sda set 1 boot on
parted /dev/sda mkpart primary fat32 798GiB 799GiB
parted /dev/sda mkpart primary linux-swap 799GiB 100%

# Format the partitions
mkfs.ext4 /dev/sda1
mkfs.fat -F32 /dev/sda2
mkswap /dev/sda3

# Mount the partitions
mount /dev/sda1 /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
mkdir /mnt/boot/efi
mount /dev/windows_partition /mnt/boot/efi # replace with actual Windows boot partition
swapon /dev/sda3

# Install base system
pacstrap /mnt base linux linux-firmware linux-headers base-devel grub efibootmgr vim git nano intel-ucode networkmanager bluez bluez-utils bluez-libs wpa_supplicant wireless_tools os-prober ntfs-3g network-manager-applet dosfstools mtools pulseaudio-bluetooth cups openssh dhcpcd xorg plasma plasma-wayland-session kde-applications neofetch

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Configure locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set hostname
echo "ArchLinux" > /etc/hostname

# Configure hosts file
echo "127.0.0.1            localhost" >> /etc/hosts
echo "::1                  localhost" >> /etc/hosts
echo "127.0.0.1            ArchLinux.localdomain localhost" >> /etc/hosts

# Set root password
passwd

# Create a new user
useradd -m -G wheel abi
passwd abi

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# Configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
grub-mkconfig -o /boot/grub/grub.cfg

# Detect other operating systems and update GRUB
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable Bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable sddm.service

# Reboot the system
umount -R /mnt
reboot
