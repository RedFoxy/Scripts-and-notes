#!/bin/bash
################################################################################
#                                                                              #
#                Home Assistant Supervised installation script                 #
#                                 (unofficial)                                 #
#                               v0.6 13/08/2022                                #
#                     by Massimo "RedFoxy Darrest" Ciccio'                     #
#       WebSite: https://redfoxy.it - GitHub: https://github.com/RedFoxy       #
#   YouTube: https://youtube.redfoxy.it - Twitter: https://twitter.redfoxy.it  #
#                                                                              #
################################################################################

################################################################################
#                               Download and run:                              #
#                  curl -fsSL ha-supervised.redfoxy.it | bash                  #
################################################################################

NEED_SUDO=`which sudo`
if [ `id -u` = 0 ]; then
  NEED_SUDO="";
else
  if [ -z $NEED_SUDO ]; then
    echo "Unable to find sudo in PATH! Please install before to continue.";
    echo "Run as root: apt-get install sudo";
    exit 2;
  fi
fi


cat <<WELCOME
################################################################################
#                                                                              #
#                Home Assistant Supervised installation script                 #
#                                 (unofficial)                                 #
#                               v0.6 13/08/2022                                #
#                     by Massimo "RedFoxy Darrest" Ciccio'                     #
#       WebSite: https://redfoxy.it - GitHub: https://github.com/RedFoxy       #
#   YouTube: https://youtube.redfoxy.it - Twitter: https://twitter.redfoxy.it  #
#                                                                              #
################################################################################

Home Assistant official WebSite: https://www.home-assistant.io/ 

This script can be run on different systems, like a Raspberry Pi, a virtual
machine, a computer with cpu x86 32/64 bit and other type hardware.
To run you need to have Debian, Raspbian or Debian derivate operative system
already installed, this script it'll uses apt-get to manage packages and it'll
installs Docker and about all dependences required by Home Assistant, this
installation it's a bit invasive so if you are not sure, please don't continue!

                                     CAUTION
                         ---> Use at your own risk! <---

################################################################################

WELCOME

sec=20

echo "Press any key to start install script, CTRL+c to cancel"
while [ true ] ; do
  read -t 1 -n 1
  if [ $? = 0 ] ; then
    break ;
  else
    if [ $sec -eq 0 ]; then
      exit 2;
    fi
    let "sec=sec-1"
  fi
done

# Update repository
$NEED_SUDO apt-get update

# Install dependences
$NEED_SUDO apt-get install -y ca-certificates curl gnupg jq wget lsb-release systemd apparmor network-manager udisks2 libglib2.0-bin dbus

ARCH=$(uname -m)
OSA=$(curl --silent "https://api.github.com/repos/home-assistant/os-agent/releases/latest" | jq -r .tag_name)

# Install Docker
curl -fsSL get.docker.com | sh

# Download and install latest os-agent
if [[ `wget -S --spider https://github.com/home-assistant/os-agent/releases/download/${OSA}/os-agent_${OSA}_linux_${ARCH}.deb 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  wget https://github.com/home-assistant/os-agent/releases/download/${OSA}/os-agent_${OSA}_linux_${ARCH}.deb -O /tmp/os-agent.deb
  $NEED_SUDO dpkg -i /tmp/os-agent.deb
  rm -rf /tmp/os-agent.deb
else
  echo "Unable to find .deb file in https://github.com/home-assistant/os-agent/releases/latest"
  exit 1
fi

# Start the installation, please select your CPU/Release version
wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb -O /tmp/homeassistant-supervised.deb
$NEED_SUDO dpkg -i /tmp/homeassistant-supervised.deb
rm -rf /tmp/homeassistant-supervised.deb

cat <<ENDSCRIPT

################################################################################

Now save your data and reboot!

After reboot, Home Assistant need some minutes, it depends from your hardware,
to complete the containers deploy, you can check if it finish to install Home
Assistant checking if at the last more than 3 containers are deployed, using the
command sudo docker ps
You'll can access to your Home Assistant browsing:

$(ip a | grep "inet " | grep -vE "(127.0.0.1|docker|hassio)" | awk '!/([0-9]*\.){3}[0-9]*/  {print "http://"$2":8123/"}')

Please, remeber to set a static ip address!

################################################################################
ENDSCRIPT
