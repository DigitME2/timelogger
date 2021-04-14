#!/bin/bash

echo "Beginning setup"
sudo apt-get -y install python-pip3
sudo pip3 install qrcode
sudo pip3 install Image
sudo apt-get -y install mariadb-client-core-10.1

echo "Launching XAMPP installer"
chmod u+x xampp-linux-x64-7.2.12-0-installer.run
sudo ./xampp-linux-x64-7.2.12-0-installer.run
sudo apt-get install net-tools
sudo /opt/lampp/xampp start

sleep 10

mysql -u root -e "CREATE DATABASE work_tracking" -S /opt/lampp/var/mysql/mysql.sock
mysql -u root -S /opt/lampp/var/mysql/mysql.sock work_tracking < work_tracking_tables.sql

mysql -u root -S /opt/lampp/var/mysql/mysql.sock mysql < user.sql

sudo cp -r timelogger /opt/lampp/htdocs/

# this is a bodge, but it works. TODO: secure this
sudo chmod -R 777 /opt/lampp/htdocs/timelogger/

# add SQL stored procedures from setupfiles using seperate script
source ./add_sql_procedures.sh

sudo cp start_job_tracking_server /etc/init.d/
sudo chmod 755 /etc/init.d/start_job_tracking_server

echo "Done. Please add a cron job to run the start-up script at boot."
