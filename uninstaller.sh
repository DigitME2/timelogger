#!/bin/bash
# ******************************************
# Program: Process Time Tracker - v.2.13
# Developer: DigitME2# Date: 09-11-2022
# Last Updated: 09-11-2022
# ******************************************

#Copyright 2022 DigitME2
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

if (( `id -u`!=0 ))
	then
		echo "Must be run as root"
		echo "USAGE: sudo ./uninstaller.sh"
		exit
fi

echo -e "\e[33mWarning: This will remove Process Time Tracker Server Software completely. And all dependencies like PHP, MySQL and Apache2 Server will be uninstalled and all files belong to them will be removed.\e[0m"
while true; do
	read -p "Do you still wish to uninstall this program?. Please be aware that after this your saved data cannot be retrieved. Please answer yes or no to continue, Enter Y for Yes, Enter N for No." yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit;;
		* ) echo "Invalid input. Please Enter Y for Yes, Enter N for No.";;
	esac
done
echo -e "\e[31mStarting uninstallation of the DigitME2 PTT Server Software. After this all your data stored in the software will be removed..\e[1m"
echo -e "\e[33mStopping PTT Server, Database server, Discovery Server..\e[0m"
systemctl stop apache2
systemctl stop mysql
systemctl stop ptt_discovery.service
echo -e "\e[33mUninstalling Apache2 Server...\e[0m"
apt-get -y -qqq purge apache2 apache2-utils apache2-bin apache2.2-common
apt-get autoremove -y
rm -R /var/www/html/timelogger
rm /var/www/html/index.php
rm /var/www/ptt_device_discovery.py
apt-get -y -qq purge 'php*'
apt-get -y -qq purge php.*
apt autoremove -y
echo -e "\e[33mRemoving Server Discovery files...\e[0m"
rm /etc/systemd/system/ptt_discovery.service
echo -e "\e[33mUninstalling MySQL Server...\e[0m"
apt-get -y -qq purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
rm -rf /etc/mysql /var/lib/mysql
echo -e "\e[42mDigitME2 Process Time Tracker Software is completely uninstalled and all files related to this were removed.\e[0m"
sleep 10
exit
