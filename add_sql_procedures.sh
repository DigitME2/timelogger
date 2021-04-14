#!/bin/bash

 echo "Adding SQL stored procedures from files-"

for file in /opt/lampp/htdocs/timelogger/scripts/initialisation/*
do
  echo "$file"
  mysql -u root -S /opt/lampp/var/mysql/mysql.sock work_tracking < "$file"
done
