# Home Assistant scripts

Collections of scripts about Home Assistant

<a href="https://www.buymeacoffee.com/redfoxydarrest" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

# Home Assistant Supervised installation script ![English](https://img.shields.io/badge/-english-blue)
[install-supervised.sh](install-supervised.sh)

This script can be run on different systems, like a Raspberry Pi, a virtual machine, a computer with cpu x86 32/64 bit and other type hardware.
To run you need to have Debian, Raspbian or Debian derivate operative system already installed, this script it'll uses apt-get to manage packages and it'll installs Docker and about all dependences required by Home Assistant, this installation it's a bit invasive so if you are not sure, please don't continue!

**CAUTION** Use at your own risk!

To run use:
bash -c "$(wget -qLO - https://ha-supervised.redfoxy.it)"

# Watch at an example of the script running:
[![Example of script running](https://raw.githubusercontent.com/RedFoxy/Scripts-and-notes/main/Home-Assistant/home%20assistant%20supervised.jpg)](https://youtu.be/CPAF4epc9a4)

# Home Assistant Supervised installation script ![Italiano](https://img.shields.io/badge/-italiano-blue)
[install-supervised.sh](install-supervised.sh)

Questo script provvederà a installare Docker e tutte le dipendenze, avrete bisogno solo di un dispositivo con Debian 10/11 o derivate, come Ubuntu, Raspbian o altre anche per CPU differenti.
Quest'installazione è alquanto invasiva, se non siete sicuri di cosa state per fare, non continuate!

**ATTENZIONE** Usate questo script a vostro rischio!

Per installare vi basta eseguire questo comando:
bash -c "$(wget -qLO - https://ha-supervised.redfoxy.it)"

# Di seguito un video che vi mostra l'intera procedura:
[![Example of script running](https://raw.githubusercontent.com/RedFoxy/Scripts-and-notes/main/Home-Assistant/home%20assistant%20supervised.jpg)](https://youtu.be/CPAF4epc9a4)
