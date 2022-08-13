# Update-DDNS

Script to update Dynamic DNS using UpdateDD or Curl

You can use multiple configurations to update different Dynamic DNS, supports every dynamic dns with url support or supported by updatedd, like OVH, DynDNS and others.

# Install

cd /opt

git clone https://github.com/RedFoxy/update-ddns

cd update-ddns

sudo chmod +x update-ddns.sh

# Example use with different config files

/opt/update-ddns/update-ddns.sh /opt/update-ddns/update-my-ddns.conf

/opt/update-ddns/update-ddns.sh /opt/update-ddns/update-other-service.conf

# Crontab
You can add taht script in yout crontab to keep updated your dynamic dns checking for update every 5 minutes:

crontab -e

*/5 * * * * /opt/update-ddns/update-ddns.sh /opt/update-ddns/update-my-ddns.conf 
