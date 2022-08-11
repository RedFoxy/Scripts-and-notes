#!/bin/bash

# IMPORTANT!
# Use this script as is it at your risk!
# Use only on Debian 10/11
# This script will install Docker and all dependeces to install Home Assistant Supervised.

# How to run:
# Download the script on the destination machine:
# wget https://raw.githubusercontent.com/RedFoxy/Scrpit-and-notes/main/Home-Assistant/install-supervised.sh
#
# Make it executable:
# chmod +x install-supervised.sh
#
# Than run it!
# ./install-supervised.sh
#
# Please, remeber to set a static ip on your computer

# Update repository
sudo apt-get update
# Install dependences
sudo apt-get install -y ca-certificates curl gnupg jq wget lsb-release systemd apparmor network-manager udisks2 libglib2.0-bin dbus

ARCH=$(uname -m)
OSA=$(curl --silent "https://api.github.com/repos/home-assistant/os-agent/releases/latest" | jq -r .tag_name)

# Apply docker gpg key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Create Docker repository based on CPU
echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update repository with the new one
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Download and install latest os-agent
if [[ `wget -S --spider https://github.com/home-assistant/os-agent/releases/download/${OSA}/os-agent_${OSA}_linux_${ARCH}.deb 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  wget https://github.com/home-assistant/os-agent/releases/download/${OSA}/os-agent_${OSA}_linux_${ARCH}.deb
  sudo dpkg -i os-agent_${OSA}_linux_${ARCH}.deb
  rm -rf /tmp/install-ha-supervised
else
  echo "Unable to find .deb file in https://github.com/home-assistant/os-agent/releases/latest"
  exit 1
fi

# Start the installation, please select your CPU/Release version
wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
sudo dpkg -i homeassistant-supervised.deb

# Now save your data and reboot!
# After reboot, Home Assistant need some minutes, it depends from your hardware, to complete the deploy,
# you can check if it finish to install Home Assistant browsing http://IP-ADDRESS:8123 and checking if at the last
# more than 3 containers are deployed, you can check the running container using: sudo docker ps
