#!/bin/bash
# ******************************************
# Program: Process Time Tracker - v.2.13
# Developer: DigitME2
# Date: 24-10-2022
# Last Updated: 24-10-2022
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

sudo rm /etc/apache2/ports.conf 
sudo rm /etc/apache2/sites-enabled/000-default.conf 
sudo cp ports.conf /etc/apache2/
sudo cp 000-default.conf /etc/apache2/sites-enabled/
sudo rm /var/www/html/timelogger/pages/header.html
sudo cp header.html /var/www/html/timelogger/pages/
sudo systemctl restart apache2
sudo rm /var/www/ptt_device_discovery.py
sudo cp ./ports_change/ptt_device_discovery.py /var/www/
sudo systemctl restart ptt_discovery.service
sudo echo -e "\e[33mSoftware running port changed to port:81\e[0m"
sleep 5
xdg-open http://localhost:81/timelogger/pages/overview_client.php </dev/null >/dev/null 2>&1 
exit
