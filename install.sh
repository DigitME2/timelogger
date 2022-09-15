#!/bin/bash
# ******************************************
# Program: Process Time Tracker - v.0.1
# Developer: DigitME2
# Date: 09-09-2022
# Last Updated: 09-09-2022
# ******************************************

sudo apt update
sudo apt-get -y install software-properties-common
sudo add-apt-repository universe
sudo apt -y install apache2
sudo ufw allow in "Apache full"
sudo apt -y install mysql-server
sudo mysql -u root -e "CREATE USER 'server'@'localhost' IDENTIFIED BY 'gnlPdNTW1HhDuQGc';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
sudo apt -y install php libapache2-mod-php php-mysql
sudo apt -y install php-mbstring php-zip php-gd php-curl php-json
cd timelogger/
sudo mv timelogger /var/www/html/
sudo rm /var/www/html/index.html
sudo cp index.php /var/www/html/
sudo systemctl restart apache2 && sudo systemctl restart mysql
sudo mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 1;"
sudo mysql -u root -e "CREATE DATABASE work_tracking" -S /var/run/mysqld/mysqld.sock  && \
sudo mysql -u root -S /var/run/mysqld/mysqld.sock work_tracking < work_tracking_db_setup.sql && \
sudo mysql -u root -S /var/run/mysqld/mysqld.sock mysql < user.sql
cd /var/www/html
sudo chmod 777 -R timelogger
sudo chmod 777 index.php
sudo systemctl restart apache2 && sudo systemctl restart mysql


    