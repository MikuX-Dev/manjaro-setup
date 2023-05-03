#!/usr/bin/env bash

# Script to setup an android build environment on Arch Linux and derivative distributions

clear
echo 'Starting Arch-based Android build setup'

# Uncomment the multilib repo, incase it was commented out
echo '[1/5] Enabling multilib repo'

# Check if multilib repository exists in pacman.conf
if grep -q "\[multilib\]" /etc/pacman.conf; then
    # Multilib repository exists, remove comment if it is commented out
  sudo sed -i '/^\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
else
    # Multilib repository does not exist, add it to pacman.conf
  echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
fi

# Sync, update, and prepare system
echo '[2/5] Syncing repositories and updating system packages'
sudo pacman -Syyu --noconfirm --needed git git-lfs multilib-devel fontconfig ttf-droid

# Install android build prerequisites
echo '[3/5] Installing Android building prerequisites'
packages="ncurses5-compat-libs lib32-ncurses5-compat-libs aosp-devel xml2 lineageos-devel"
for package in $packages; do
    echo "Installing $package"
    git clone https://aur.archlinux.org/"$package"
    cd "$package" || exit
    makepkg -si --skippgpcheck --noconfirm --needed
    cd - || exit
    rm -rf "$package"
done

# Check if Java 17 is the default version
#if java -version 2>&1 | grep -q "version \"17"; then
#    echo "Java 17 is already the default version."
#else
    # Install Java 17
#    echo "Java 17 is not the default version. Installing..."
#    sudo pacman -S jdk17-openjdk --noconfirm
    
     # Set Java 17 as the default version
#    sudo archlinux-java set java-17-openjdk
#    echo "Java 17 installed and set as the default version successfully."
#fi

# Install adb and associated udev rules
echo '[4/5] Installing adb convenience tools'
sudo pacman -S --noconfirm --needed android-tools android-udev

# Check if yay is installed
if ! command -v yay &> /dev/null
then
    # Prompt the user before installing yay
    read -p "yay not found. Do you want to install yay? (yes/no) " answer
    if [ "$answer" == "yes" ]; then
        # Clone yay.git from GitHub
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        echo "yay not installed. Exiting script."
        exit 1
    fi
fi

# Install from yay
#yay -S --noconfirm android-sdk

# Path
#shell=$(basename $SHELL)
#path='/opt/android-sdk/tools:/opt/android-sdk/platform-tools:/opt/android-build:$PATH'

#if [ "$shell" = "bash" ]; then
#    if [ -f "$HOME/.bashrc" ]; then
#        echo "export PATH=\"$path\"" >> "$HOME/.bashrc"
#        echo "Added PATH to .bashrc"
#    else
#        echo "No .bashrc file found, PATH not added"
#        exit 1
#    fi
#elif [ "$shell" = "zsh" ]; then
#    if [ -f "$HOME/.zshrc" ]; then
#        echo "export PATH=\"$path\"" >> "$HOME/.zshrc"
#        echo "Added PATH to .zshrc"
#   else
#        echo "No .zshrc file found, PATH not added"
#        exit 1
#    fi
#else
#    echo "Unknown shell, PATH not added"
#    exit 1
#fi

# Update system
#read -p "Do you want to update your system? (yes/no) " answer

#if [ "$choice" == "yes" ]; then
#    echo "Updating the system..."
#    sudo pacman -Syu
#    echo "System updated successfully."
#else
#    echo "Exiting without updating the system."
#fi

# Config git
read -p "Which git-config to use? (personal 'P'/organisation 'O') " answer

if [ "$answer" == "P" ] || [ "$answer" == "p" ] || [ "$answer" == "personal" ]; then
    echo "Configuring personal git-config"
    ./aosp-setup/personal-setup/personal.sh
    echo "Personal git-configured successfully."
elif [ "$answer" == "O" ] || [ "$answer" == "o" ] || [ "$answer" == "organisation" ]; then
    echo "Configuring org git-config"
    ./aosp-setup/personal-setup/organisation.sh
    echo "Organisation git-configured successfully."
else
    echo "Invalid input, please enter 'P' or 'O'"
fi

#Set apps for coding

# Complete
echo 'Setup completed, enjoy'
