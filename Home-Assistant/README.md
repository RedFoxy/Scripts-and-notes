# Home Assistant scripts

Collections of scripts about Home Assistant

# Home Assistant Supervised installation script
[install-supervised.sh](install-supervised.sh)

This script can be run on different systems, like a Raspberry Pi, a virtual machine, a computer with cpu x86 32/64 bit and other type hardware.
To run you need to have Debian, Raspbian or Debian derivate operative system already installed, this script it'll uses apt-get to manage packages and it'll installs Docker and about all dependences required by Home Assistant, this installation it's a bit invasive so if you are not sure, please don't continue!
**CAUTION** Use at your own risk!

To run use:
bash -c "$(wget -qLO - https://ha-supervised.redfoxy.it)"
