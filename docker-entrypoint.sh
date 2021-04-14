#!/bin/bash

/opt/lampp/xampp start
sleep 20
mysql -u root -e "SET GLOBAL event_scheduler = ON" -S /opt/lampp/var/mysql/mysql.sock

# To keep the docker container alive
sleep infinity
