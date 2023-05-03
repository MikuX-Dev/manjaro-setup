#!/usr/bin/env sh

# Config git 
read -p "Which git-config to use? (personal/org) " answer

if [ "$answer" == "personal" ]; then
    echo "Configuring personal git-config"
    ../personal-setup/personal.sh
    echo "Personal git-configured successfully."
else
    echo "Configuring org git-config"
    ../personal-setup/org.sh
    echo "Org git-configured successfully."
fi