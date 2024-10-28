#!/bin/bash
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#                                                                              !
#                          Use this to run the script:                         !
#                                                                              !
#          bash -c "$(wget -qLO - https://hasupervised.redfoxy.it)"           !
#                                                                              !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ver="v0.9.9 28/10/2024"
sec=20
ShowLOG=0   # 0: Save log - 1: Print long in output
PathLOG="/var/log/ha-supervised.log"
TMPPATH="/tmp/hasupervised"

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

clear
cat <<WELCOME
####################################################################################################
#                                                                                                  #
#                           Home Assistant Supervised installation script                          #
#                                           (unofficial)                                           #
#                                        $ver                                         #
#                               by Massimo "RedFoxy Darrest" Ciccio'                               #
#                                My network: https://me.redfoxy.eu/                                #
#                                                                                                  #
####################################################################################################

WELCOME

. /etc/os-release

shopt -s nocasematch

if [[ ! $NAME =~ "debian" ]]; then
  echo "[ERROR!] $NAME $VERSION is not supported!" >&2
  echo "Only Debian 11 and Debian 12 are supported."
  exit 1;
else
  if [[ ${VERSION_ID%%.*} -le 10 ]]; then
    echo "[ERROR!] $NAME $VERSION is not supported!" >&2
    echo "Only Debian 11 and Debian 12 are supported."
    exit 1;
  fi
fi

if [ -z "$TMPPATH" ]; then
  echo "[ERROR] Temporary directory variable TMPPATH is not set!" >&2
  exit 1
fi

$binSudo mkdir -p $TMPPATH

if [ -f $TMPPATH/config.env ]; then
    source config.env
fi

$binSudo rm -rf $TMPPATH/*.deb $TMPPATH/*.sh

if [ $ShowLOG == 0 ]; then
  $binSudo rm -rf $PathLOG
  if [ ! -z $binSudo ]; then
    $binSudo touch $PathLOG
    $binSudo chown $(whoami) $PathLOG
  fi
fi

if [ -z "$nic" ]; then
  lnic=$(grep -lri up /sys/class/net/*/device/net/*/operstate 2> /dev/null | cut -d/ -f5);
  nnic=($lnic);nnic=${#nnic[@]};

  if [[ $nnic -ge 1 ]]; then
    if [[ $nnic -gt 1 ]]; then
      while :
      do
        clear
        echo "Found multiple network interfaces active, which one is it connected to the LAN?";
        echo "";

        anic=0;
        for x in $(grep -lri up /sys/class/net/*/device/net/*/operstate 2> /dev/null | cut -d/ -f5);
        do
        echo $anic: $x - $(ip addr show $nic | grep "inet " | tr -s ' ' | cut -d' ' -f 3 | cut -d/ -f 1);
        nicList[$anic]=$x;
        anic=$((anic+1))
        done

        echo "";
        echo -n "Please select a network card: "
        read -n 1 -t 15 a
        printf "\n"
        if [[ "$a" =~ ^[0-9]+$ ]]; then
          if [ ! -z ${nicList[$a]} ]; then
            nic="${nicList[$a]}";
            echo $nic
            exit 0;
          fi
        fi
      done
    else
      nic=$lnic;
    fi
  else
    echo "[ERROR] Unable to find network adapter connected, please plug the cable or connect to the wifi before continue!" >&2
    exit 1;
  fi
  echo "nic=$nic" >> $TMPPATH/config.env
fi

IPADDR=$(printf '%s\n' $(ip addr show $nic | grep "inet " | tr -s ' ' | cut -d' ' -f 3 | cut -d/ -f 1))

if command -v docker &> /dev/null; then
  if [ "$(docker ps -q -f name=hassio_supervisor)" ]; then
    echo "The HassIO Supervisor container is running correctly."
    if [ "$(docker ps -q -f name=hassio_cli)" ] && [ "$(docker ps -q -f name=homeassistant)" ]; then
      echo "The installation of Home Assistant appears to be completed."
      echo "To access go to the following URL using a browser:"
    else
      echo "The installation of Home Assistant appears to still be in progress."
      echo "To follow the installation progress, and then log in, go to the following URL using a browser:"
    fi
    echo ""
    echo "$(tput smul)http://$IPADDR:8123$(tput sgr0)"
    echo ""

    exit 0
  fi
fi

cat <<MESSAGE
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
MESSAGE

while [ true ] ; do
  read -t 1 -n 1
  if [ $? = 0 ] ; then
    break ;
  else
    if [ $sec -eq 0 ]; then
      echo "Cancelled installation!"
      exit 0;
    fi
    let "sec=sec-1"
  fi
done

if [[ "$(ip a s $nic)" == *"dynamic"* ]]; then
cat <<DHCP
----------------------------------------------------------------------------------------------------

The interface $nic is using DHCP.
It is highly recommended to set a static ip a after installation.

----------------------------------------------------------------------------------------------------

DHCP
fi

#------------------------------------------------------------------------------------------------------------
install_dep() {
  for pkg in $1
  do
    if ! dpkg -s $pkg >/dev/null 2>&1; then
      echo -n "Installing $pkg..."

      if [ $ShowLOG == 0 ]; then
        $binSudo apt-get -y install $pkg >> $PathLOG 2>&1
      else
        $binSudo apt-get -y install $pkg
      fi

      if [[ $? > 0 ]]; then
        echo $msgFail
        echo "----------------------------------------------------------------------------------------------------" >&2
        echo "Unable to install $pkg" >&2
        echo "Please check your internet connection and repositories." >&2
        if [ $ShowLOG == 0 ]; then
          echo "You can find the log in "$PathLOG >&2
          echo ""
          echo "Last 10 lines of the log are:" >&2
          tail -n 10 $PathLOG >&2
        fi
        echo "----------------------------------------------------------------------------------------------------" >&2
        exit 1;
      else
        echo $msgDone
      fi
    fi
  done
}
#------------------------------------------------------------------------------------------------------------

echo -n "Update repositories..."
if [ $ShowLOG == 0 ]; then
  $binSudo apt-get update -o APT::Update::Error-Mode=any >> $PathLOG 2>&1
else
  $binSudo apt-get update -o APT::Update::Error-Mode=any
fi

if [[ $? > 0 ]]; then
  echo $msgFail
  echo "----------------------------------------------------------------------------------------------------" >&2
  echo "Unable to update repositories!" >&2
  echo "Please check your internet connection and repositories config files." >&2
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG >&2
    echo ""
    echo "Last 10 lines of the log are:" >&2
    tail -n 10 $PathLOG >&2
  fi
  echo "----------------------------------------------------------------------------------------------------" >&2
  exit 1;
else
  echo $msgDone
fi

install_dep "ca-certificates jq curl wget"

if [[ ! `wget -S --spider https://github.com/ 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo "[ERROR] Unable to connect to github.com, please check yout internet connection and network setting." >&2
  exit 1
fi

if [[ ! `wget -S --spider https://api.github.com/ 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo "[ERROR] Unable to connect to api.github.com, please check yout internet connection and network setting." >&2
  exit 1
fi

OSAgent=$(curl --silent "https://api.github.com/repos/home-assistant/os-agent/releases/latest" | jq -r '.assets | .[].browser_download_url' | grep -i $(uname -m))

if [[ `wget -S --spider $OSAgent 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo -n "Download os-agent..."
  if [ $ShowLOG == 0 ]; then
    wget $OSAgent -O $TMPPATH/os-agent.deb >> $PathLOG 2>&1
  else
    wget $OSAgent -O $TMPPATH/os-agent.deb
  fi
  if [ ! -e "$TMPPATH/os-agent.deb" ] || [ ! -r "$TMPPATH/os-agent.deb" ] || [ ! -s "$TMPPATH/os-agent.deb" ]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "[ERROR] Unable to connect or download from github.com/home-assistant/os-agent, please check yout internet connection and network setting." >&2
    echo "Unable to download or save os-agent.deb." >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    echo "----------------------------------------------------------------------------------------------------" >&2
    exit 1
  fi
  echo $msgDone
else
  echo "----------------------------------------------------------------------------------------------------" >&2
  echo "[ERROR] Unable to connect or download from github.com/home-assistant/os-agent, please check yout internet connection and network setting." >&2
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG >&2
    echo ""
    echo "Last 10 lines of the log are:" >&2
    tail -n 10 $PathLOG >&2
  fi
  echo "----------------------------------------------------------------------------------------------------" >&2
  exit 1
fi

if [[ `wget -S --spider https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo -n "Download homeassistant-supervised..."
  if [ $ShowLOG == 0 ]; then
    wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb -O $TMPPATH/homeassistant-supervised.deb >> $PathLOG 2>&1
  else
    wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb -O $TMPPATH/homeassistant-supervised.deb
  fi
  if [ ! -e "$TMPPATH/homeassistant-supervised.deb" ] || [ ! -r "$TMPPATH/homeassistant-supervised.deb" ] || [ ! -s "$TMPPATH/homeassistant-supervised.deb" ]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "[ERROR] Unable to connect or download from github.com/home-assistant/supervised-installer, please check yout internet connection and network setting." >&2
    echo "Unable to download or save homeassistant-supervised.deb." >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    exit 1
    echo "----------------------------------------------------------------------------------------------------" >&2
  fi
  echo $msgDone
else
  echo "----------------------------------------------------------------------------------------------------" >&2
  echo "[ERROR] Unable to connect or download from github.com/home-assistant/supervised-installer, please check yout internet connection and network setting." >&2
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG >&2
    echo ""
    echo "Last 10 lines of the log are:" >&2
    tail -n 10 $PathLOG >&2
  fi
  echo "----------------------------------------------------------------------------------------------------" >&2
  exit 1
fi

if [[ `wget -S --spider https://get.docker.com 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  echo -n "Download Docker install script..."
  if [ $ShowLOG == 0 ]; then
    wget https://get.docker.com -O $TMPPATH/docker.sh >> $PathLOG 2>&1
  else
    wget https://get.docker.com -O $TMPPATH/docker.sh
  fi
  if [ ! -e "$TMPPATH/docker.sh" ] || [ ! -r "$TMPPATH/docker.sh" ] || [ ! -s "$TMPPATH/docker.sh" ]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "[ERROR] Unable to connect or download from get.docker.com, please check yout internet connection and network setting." >&2
    echo "Unable to download or save Docker install script." >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    echo "----------------------------------------------------------------------------------------------------" >&2
    exit 1
  fi
  echo $msgDone
else
  echo "----------------------------------------------------------------------------------------------------" >&2
  echo "[ERROR] Unable to connect or download from get.docker.com, please check yout internet connection and network setting." >&2
  if [ $ShowLOG == 0 ]; then
    echo "You can find the log in "$PathLOG >&2
    echo ""
    echo "Last 10 lines of the log are:" >&2
    tail -n 10 $PathLOG >&2
  fi
  echo "----------------------------------------------------------------------------------------------------" >&2
  exit 1
fi

install_dep "apparmor bluez cifs-utils dbus gnupg inetutils-ping libglib2.0-bin lsb-release nfs-common udisks2"

DHCP_LEASES_DIR="/var/lib/dhcp"
if [ -d "$DHCP_LEASES_DIR" ] && ls "$DHCP_LEASES_DIR"/dhclient*.lease* 1> /dev/null 2>&1; then
  DHCP_FILES=$(ls $DHCP_LEASES_DIR/dhclient*.lease* 2>/dev/null)
  for file in $DHCP_FILES; do
    dnsDHCP=$(grep -h 'option domain-name-servers' "$file" | awk '{print $3}' | tr -d ';' | xargs)
  done
fi

if systemctl is-active --quiet systemd-resolved; then
  if command -v resolvectl >/dev/null 2>&1; then
    dnsRESOLV=$(resolvectl status | sed -n '/DNS Servers:/,/DNS Domain:/p' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | tr '\n' ' ')
  elif command -v systemd-resolve >/dev/null 2>&1; then
    dnsRESOLV=$(systemd-resolve --status | sed -n '/DNS Servers:/,/DNS Domain:/p' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | tr '\n' ' ')
  fi

  if [ -z "$dnsRESOLV" ] && [ -f /etc/systemd/resolved.conf ]; then
    dnsRESOLV=$(grep -E '^\s*DNS=' /etc/systemd/resolved.conf | cut -d= -f2 | xargs)
  fi
fi

if systemctl is-active --quiet NetworkManager; then
  CONNECTIONS=$(nmcli -t -f NAME connection show --active)
  for conn in $CONNECTIONS; do
    dnsNMCLI=$(nmcli -g IP4.DNS connection show "$conn" | xargs)
  done
fi

if systemctl is-active --quiet systemd-networkd; then
  DNS_ENTRIES=$(grep -hr 'DNS=' /etc/systemd/network/*.network 2>/dev/null | cut -d= -f2 | xargs)
  if [ -n "$DNS_ENTRIES" ]; then
    dnsNETW="$DNS_ENTRIES"
    return 0
  fi
fi

if [ -f /etc/resolv.conf ]; then
  dnsFILE=$(grep -E '^\s*nameserver' /etc/resolv.conf | awk '{print $2}' | xargs)
fi

dns=$(echo "$dnsDHCP $dnsRESOLV $dnsNMCLI $dnsNETW $dnsFILE" | sed 's/127\(\.[0-9]*\)\{3\}//g' | xargs)

if [ -z "${dns// /}" ]; then
  loop=true
  while $loop; do
    echo "No dns server found!"
    read -p "Enter DNS Server: " test
    if [[ $test =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$ ]]; then
      dns="$test"
      loop=false
    else
      echo "Invalid DNS Server. Please try again."
    fi
  done
fi

if ! command -v resolveconf; then
  if ([[ $NAME =~ "debian" ]] && [[ ${VERSION_ID%%.*} -gt 11 ]]) then
    install_dep "systemd-resolved"

    if [ $ShowLOG == 0 ]; then
      $binSudo systemctl enable systemd-resolved >> $PathLOG 2>&1
      $binSudo systemctl restart systemd-resolved >> $PathLOG 2>&1
    else
      $binSudo systemctl enable systemd-resolved
      $binSudo systemctl restart systemd-resolved
    fi
  fi
fi

if command -v resolveconf; then
  declare -A dns_unique
  for testdns in $dns; do
    dns_unique["$testdns"]=1
  done

  for serverdns in "${!dns_unique[@]}"; do
    if [ $ShowLOG == 0 ]; then
      $binSudo resolvectl dns "$nic" "$serverdns" >> $PathLOG 2>&1
    else
      $binSudo resolvectl dns "$nic" "$serverdns"
    fi
  done
fi

install_dep "systemd systemd-journal-remote network-manager"

if ! command -v docker &> /dev/null; then
  echo -n "Installing Docker..."

  if [ $ShowLOG == 0 ]; then
    sh $TMPPATH/docker.sh >> $PathLOG 2>&1
  else
    sh $TMPPATH/docker.sh
  fi

  docker -h > /dev/null 2>&1
  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "Unable to install Docker" >&2
    echo "Please check your internet connection!" >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    echo "----------------------------------------------------------------------------------------------------" >&2
    exit 1
  else
    echo $msgDone
  fi
fi

if ! dpkg -s os-agent >/dev/null 2>&1; then
  echo -n "Installing OS-Agent..."
  if [ $ShowLOG == 0 ]; then
    $binSudo dpkg -i $TMPPATH/os-agent.deb >> $PathLOG 2>&1
  else
    $binSudo dpkg -i $TMPPATH/os-agent.deb
  fi

  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "Unable to install "$OSAgent >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    echo "----------------------------------------------------------------------------------------------------" >&2
    exit 1
  else
    echo $msgDone
  fi
fi

if ! dpkg -s homeassistant-supervised >/dev/null 2>&1; then
  echo -n "Deploy Home Assistant containers..."
  if [ $ShowLOG == 0 ]; then
    $binSudo dpkg -i $TMPPATH/homeassistant-supervised.deb >> $PathLOG 2>&1
  else
    $binSudo dpkg -i $TMPPATH/homeassistant-supervised.deb
  fi

  if [[ $? > 0 ]]; then
    echo $msgFail
    echo "----------------------------------------------------------------------------------------------------" >&2
    echo "Unable to install https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb" >&2
    if [ $ShowLOG == 0 ]; then
      echo "You can find the log in "$PathLOG >&2
      echo ""
      echo "Last 10 lines of the log are:" >&2
      tail -n 10 $PathLOG >&2
    fi
    echo "----------------------------------------------------------------------------------------------------" >&2
    exit 1
  else
    echo $msgDone
  fi
fi

while true; do
    if docker ps --filter "name=hassio_supervisor" --filter "status=running" | grep -q "hassio_supervisor"; then
        echo "The installation of Home Assistant appears to still be in progress."
        echo "To follow the installation progress, and then log in, go to the following URL using a browser:"
        echo ""
        echo "$(tput smul)http://$IPADDR:8123$(tput sgr0)"
        echo ""
        break
    else
        echo "Waiting for deploy of hassio_supervisor..."
    fi

    sleep 5
done
