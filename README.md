# Process Time Tracker (Timelogger) WebApp
This software allows you to Track your Process Times through your Production stages. With the help of Android Tablets. 

This constitutes the main server application, which will receives live process status with the help of your user interactions 
through our Android Application. Which can be accessed through our Main server web application.

This software is accompanied by an Andriod App, which connects to the server and takes manual input to set the 
state of its assigned machine. [The Android App APK can be downloaded from here.](https://github.com/DigitME2/timelogger/releases/tag/v2.14)

# Installing with installer
Ubuntu installer file for installing this software can also be found here. 
[The Main web app installer file can be downloaded from here.](https://github.com/DigitME2/timelogger/releases/tag/v2.14)

Download our ubuntu-installer.sh file by clicking on that, and go to your Downloads folder and open the terminal 
by right clicking with your mouse and select "Open in Terminal" option from the right-click menu.

And run the installer by using the following command. 

`sh ubuntu-installer.sh`

# Quick Installation
The software can be automatically set up by running these commands in a terminal in Ubuntu 22.04.

Press Ctrl + Alt + T to open a terminal. To paste into a terminal, use Ctrl + Shift + V

Install curl (Enter your password if prompted):

`sudo apt-get -y install curl`

Run the installation script:

`bash <(curl -sL https://raw.githubusercontent.com/DigitME2/timelogger/main/install.sh)`

This will download the software and set it to run on startup. The software can be reached by opening a browser and entering "localhost" into the address bar. 

#Manual Installation
(Tested on Ubuntu 22.04)

Install Git in your computer with the following command:

`sudo apt-get install git`

clone our timelogger reposiratory from our github page, by using following command:

`https://github.com/DigitME2/timelogger.git`

Go to timelogger folder in your home directory and open the terminal 
by right clicking with your mouse and select "Open in Terminal" option from the right-click menu.

And run the installer file by using the following command and give your system password if prompted.

`sh install.sh`

Please read ReadMe.txt for any other requirements. Thank you.
