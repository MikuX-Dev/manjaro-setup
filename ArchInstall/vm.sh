#!/bin/bash

# Check for UEFI system
if [[ -d "/sys/firmware/efi/efivars" ]]; then
    echo "UEFI system detected."
    UEFI=1
else
    echo "Non-UEFI system detected."
    UEFI=0
fi

# Set time and date
timedatectl set-ntp true
timedatectl set-timezone Asia/Kolkata

# Create partitions
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary ext4 1MiB 17.5GiB
parted /dev/sda set 1 boot on
parted /dev/sda mkpart primary fat32 17.5GiB 18GiB
parted /dev/sda mkpart primary linux-swap 18GiB 20GiB

# Format partitions
mkfs.ext4 /dev/sda1
mkfs.fat -F 32 /dev/sda2
mkswap /dev/sda3

# Mount partitions
mount /dev/sda1 /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
if [[ $UEFI -eq 1 ]]; then
    mkdir /mnt/boot/efi
    mount /dev/sdXN /mnt/boot/efi # replace sdXN with the actual partition for the Windows boot loader
fi
swapon /dev/sda3

# Install base packages
if [[ $UEFI -eq 1 ]]; then
    efibootmgr 
if
pacstrap /mnt base base-devel linux linux-firmware linux-headers grub vim nano networkmanager bluez bluez-utils bluez-libs wpa_supplicant wireless_tools os-prober ntfs-3g network-manager-applet dosfstools mtools pulseaudio-bluetooth xorg plasma plasma-wayland-session kde-applications cups openssh dhcpcd neofetch

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt

# Set time and date
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Uncomment en_US.UTF-8 in /etc/locale.gen
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set hostname
echo "ArchLinux" > /etc/hostname

# Configure hosts file
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.0.1 ArchLinux.localdomain ArchLinux" >> /etc/hosts

# Set root password
passwd

# Create user and set password
useradd -m -G wheel abi
passwd abi

# Grant sudo access to wheel group
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# Configure GRUB
if [[ $UEFI -eq 1 ]]; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/g' /etc/default/grub
if
    grub-install
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
