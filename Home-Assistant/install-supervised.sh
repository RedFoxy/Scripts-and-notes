#!/bin/bash

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#                                                                              !
#                          Use this to run the script:                         !
#                                                                              !
#          bash -c "$(wget -qLO - https://hasupervised.redfoxy.it)"           !
#                                                                              !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

sec=20
ShowLOG=0   # 0: Save log - 1: Print long in output
PathLOG="/var/log/ha-supervised.log"

msgDone=" $(tput bold; tput setb 4; tput setaf 2)Done!$(tput sgr0)"
msgFail=" $(tput bold; tput setb 4; tput setaf 1)FAILED!$(tput sgr0)"

if [ `id -u` = 0 ]; then
  binSudo="";
else
  binSudo=`which sudo`
  if [ -z $binSudo ]; then
    echo "Unable to find sudo in PATH! Please install before to continue.";
    echo "Run as root: apt-get install sudo";
    exit 1;
  fi
fi

cat <<WELCOME
####################################################################################################
#                                                                                                  #
#                           Home Assistant Supervised installation script                          #
#                                           (unofficial)                                           #
#                                        v0.8.1 25/10/2022                                         #
#                               by Massimo "RedFoxy Darrest" Ciccio'                               #
#                 WebSite: https://redfoxy.it - GitHub: https://github.com/RedFoxy                 #
#            YouTube: https://youtube.redfoxy.it - Twitter: https://twitter.redfoxy.it             #
#                                                                                                  #
####################################################################################################

Home Assistant official WebSite: https://www.home-assistant.io/

This script can be run on different systems, like a Raspberry Pi, a virtual machine, a computer with
cpu x86 32/64 bit and other type hardware.
To run you need to have Debian, Raspbian or other Debian distros already installed, this script
it'll uses apt-get to manage packages and it'll installs Docker and about all dependences
required by Home Assistant, this installation it's a bit invasive so if you are not sure, please
don't continue!

                                             $(tput blink; tput bold; tput setb 4; tput setaf 1)CAUTION!$(tput sgr0)
                                 $(tput blink; tput bold)---> Use at your own risk! <---$(tput sgr0)

####################################################################################################

Press any key to start install script, $(tput bold)CTRL+c$(tput sgr0) or $(tput bold)wait $sec$(tput sgr0) to cancel

WELCOME

while [ true ] ; do
  read -t 1 -n 1
  if [ $? = 0 ] ; then
    break ;
  else
    if [ $sec -eq 0 ]; then
      echo "Cancelled installation!"
      exit 1;
    fi
    let "sec=sec-1"
  fi
done

if [ $ShowLOG == 0 ]; then
  $binSudo rm -rf $PathLOG
  if [ ! -z $binSudo ]; then
    $binSudo touch $PathLOG
    $binSudo chown $(whoami) $PathLOG
  fi
fi

IPAddr=$(ip a | grep "inet " | grep -vE "(127.0.0.1|docker|hassio)" | cut -d'/' -f 1 | awk '!/([0-9]\.){3}[0-9]*/ {print "http://"$2":8123/"}')

if [ -z "$IPAddr" ]; then
  echo "Unable to find a valid ip address, please check your configuration and check if your adapter is connected."
  exit 1;
fi

if [[ ! `wget -S --spider https://github.com/ 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo "Unable to connect to github.com, please check yout internet connection and network setting."
  exit 1
fi

# Update repository
echo -n "Update repositories..."
if [ $ShowLOG == 0 ]; then
  $binSudo apt-get update -o APT::Update::Error-Mode=any >> $PathLOG 2>&1
else
  $binSudo apt-get update -o APT::Update::Error-Mode=any
fi

if [[ $? > 0 ]]; then
  echo $msgFail
  echo "----------------------------------------------------------------------------------------------------"
  echo "Unable to update repositories!"
  echo "Please check your internet connection and repositories config files."
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG
  fi
  echo "----------------------------------------------------------------------------------------------------"
  exit 1;
else
  echo $msgDone
fi

# Install needs
needs="ca-certificates curl gnupg systemd-journal-remote jq wget lsb-release systemd inetutils-ping apparmor network-manager udisks2 libglib2.0-bin dbus"

for pkg in $needs
do
  echo -n "Installing $pkg..."
  if [ $ShowLOG == 0 ]; then
    $binSudo apt-get -y install $pkg >> $PathLOG 2>&1
  else
    $binSudo apt-get -y install $pkg
  fi

  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------"
    echo "Unable to install $pkg"
    echo "Please check your internet connection and repositories."
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG
    fi
    echo "----------------------------------------------------------------------------------------------------"
    exit 1;
  else
    echo $msgDone
  fi
done

# Install Docker
echo -n "Installing Docker..."
if [ $ShowLOG == 0 ]; then
  curl -fsSL get.docker.com | sh >> $PathLOG 2>&1
else
  curl -fsSL get.docker.com | sh
fi

docker -h > /dev/null 2>&1
if [[ $? > 0 ]]; then
  echo $msgFail
  echo "----------------------------------------------------------------------------------------------------"
  echo "Unable to install Docker"
  echo "Please check your internet connection!"
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG
  fi
  echo "----------------------------------------------------------------------------------------------------"
  exit 1
else
  echo $msgDone
fi

# Download and install latest os-agent
echo -n "Installing OS-Agent..."
OSAgent=$(curl --silent "https://api.github.com/repos/home-assistant/os-agent/releases/latest" | jq -r '.assets | .[].browser_download_url' | grep -i $(uname -m))

if [[ `wget -S --spider $OSAgent 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  if [ $ShowLOG == 0 ]; then
    wget $OSAgent -O /tmp/os-agent.deb >> $PathLOG 2>&1
    $binSudo dpkg -i /tmp/os-agent.deb >> $PathLOG 2>&1
  else
    wget $OSAgent -O /tmp/os-agent.deb
    $binSudo dpkg -i /tmp/os-agent.deb
  fi

  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------"
    echo "Unable to install "$OSAgent
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG
    fi
    echo "----------------------------------------------------------------------------------------------------"
    exit 1
  else
    echo $msgDone
  fi

  rm -rf /tmp/os-agent.deb
else
  echo $msgFail
  echo "----------------------------------------------------------------------------------------------------"
  echo "Unable to find .deb file in https://github.com/home-assistant/os-agent/releases/latest"
  echo "----------------------------------------------------------------------------------------------------"
  exit 1
fi


# Start the installation
echo -n "Download and deploy Home Assistant containers... "
if [[ `wget -S --spider https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  if [ $ShowLOG == 0 ]; then
    wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb -O /tmp/homeassistant-supervised.deb >> $PathLOG 2>&1
    $binSudo dpkg -i /tmp/homeassistant-supervised.deb >> $PathLOG 2>&1
  else
    wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb -O /tmp/homeassistant-supervised.deb
    $binSudo dpkg -i /tmp/homeassistant-supervised.deb
  fi

  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------"
    echo "Unable to install https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb"
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG
    fi
    echo "----------------------------------------------------------------------------------------------------"
    exit 1
  else
    echo $msgDone
  fi

  rm -rf /tmp/homeassistant-supervised.deb
else
  echo $msgFail
  echo "----------------------------------------------------------------------------------------------------"
  echo "Unable to find dowload https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb"
  echo "----------------------------------------------------------------------------------------------------"
  exit 1
fi

cat <<ENDSCRIPT

####################################################################################################

Now save your data and reboot!

After reboot, Home Assistant need some minutes, it depends from your hardware, to complete the
containers deploy, you can check if it finish to install Home Assistant checking if at the last more
than 3 containers are deployed, using the command: $(tput bold)sudo docker ps$(tput sgr0)
You'll can access to your Home Assistant browsing:

$(tput smul)$(printf '%s\n' $IPAddr)$(tput sgr0)

Please, remeber to set a static ip address!

####################################################################################################
ENDSCRIPT
