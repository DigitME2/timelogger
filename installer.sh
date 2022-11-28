#!/bin/bash

# ******************************************
# Program: Process Time Tracker - v.2.13
# Developer: DigitME2# Date: 24-11-2022
# Last Updated: 24-11-2022
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
		echo "USAGE: sudo ./installer.sh"
		exit
fi

echo "Starting Installation..."
echo -e "\e[33mPlease note that this software installer targets a fresh installed Ubuntu 22.04 system. If you have any other server running on port:80 Please stop them as shown in examples.\e[0m"
echo -e "\e[33mexamples- 'sudo systemctl stop nginx' and, 'sudo systemctl stop mysql' and so on....\e[0m" 
echo -e "\e[33mAlso if any other our DigitME2 softwares are running please use the same like example way to stop them for a while and run install.sh. After this installation use 'sh ports_change.sh' to change this software server to run on port:81. And then please start other services by using examples like, example- 'sudo systemctl restart nginx' and, 'sudo systemctl restart mysql' and so on.\e[0m"
while true; do
	read -p "Do you still wish to continue to install this software?. Please answer yes or no to continue, Enter Y for Yes, Enter N for No." yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit;;
		* ) echo "Invalid input. Please Enter Y for Yes, Enter N for No.";;
	esac
done
echo -e "\e[42mStarting installation of the DigitME2 PTT Server Software.\e[0m" 
echo -e "\e[33mInstalling apt packages...\e[0m"
apt-get update
echo -e "\e[33mInstalling software-properties...\e[0m"
apt-get -y install -qq software-properties-common
add-apt-repository -y universe
echo -e "\e[33mInstalling Apache2 Server...\e[0m"
apt -y -qq install apache2
ufw allow in "Apache full"
echo -e "\e[33mInstalling MySQL Server...\e[0m"
apt -y -qq install mysql-server
mysql -u root -e "CREATE USER 'server'@'localhost' IDENTIFIED BY 'gnlPdNTW1HhDuQGc';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
echo -e "\e[33mInstalling PHP & Other requirements for PHP.\e[0m"
apt -y -qqq install php libapache2-mod-php php-mysql
apt -y -qqq install php-mbstring php-zip php-gd php-curl php-json
cp -rf timelogger /var/www/html/
rm /var/www/html/index.html
cp index.php /var/www/html/
cp ptt_device_discovery.py /var/www/
cp ptt_discovery.service /etc/systemd/system/
systemctl restart apache2 && sudo systemctl restart mysql
systemctl enable ptt_discovery.service
systemctl start ptt_discovery.service
mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -u root -e "CREATE DATABASE work_tracking" -S /var/run/mysqld/mysqld.sock  && \
mysql -u root -S /var/run/mysqld/mysqld.sock work_tracking < work_tracking_db_setup.sql && \
mysql -u root -S /var/run/mysqld/mysqld.sock mysql < user.sql
cd /var/www/html
chmod 777 -R timelogger
chmod 777 index.php
systemctl restart apache2 && sudo systemctl restart mysql
systemctl restart ptt_discovery.service
echo -e "\e[42mProcess Time Tracker Software Installed Successfully.\e[0m"
echo -e "\e[33mTo change the server ports. Please read the readme.txt file for further information.\e[0m"
echo -e "\e[42mInstallation Completed. Please open your browser and go to localhost.\e[0m"
sleep 5
xdg-open http://localhost/timelogger/pages/overview_client.php </dev/null >/dev/null 2>&1 
exit


    
