# Process Time Tracker (Timelogger) WebApp
This software allows you to Track your Process Times through your Production stages. With the help of Android Tablets. 

This constitutes the main server application, which will receives live process status with the help of your user interactions 
through our Android Application. Which can be accessed through our Main server web application.

This software is accompanied by an Andriod App, which connects to the server and takes manual input to set the 
state of its assigned machine. [The Android App APK can be downloaded from here.](https://github.com/DigitME2/timelogger/releases/tag/v3.0)

# Installing with installer
Ubuntu installer file for installing this software can also be found here. 
[The Main web app installer file can be downloaded from here.](https://github.com/DigitME2/timelogger/releases/tag/v3.0)

Download our ubuntu-installer.sh file by clicking on that, and go to your Downloads folder and open the terminal 
by right clicking with your mouse and select "Open in Terminal" option from the right-click menu.

And run the installer by using the following command. 

```
sh ubuntu-installer.sh
```

``` Installer will get paused with text 'librdkafka installation path? [autodetect] :' Then please press enter to resume installation. ```

# Manual Installation
(Tested on Ubuntu 22.04)

Install Git in your computer with the following command:

```
sudo apt-get install git
```

clone our timelogger reposiratory from our github page, by using following command:

```
git clone https://github.com/DigitME2/timelogger.git
```

Go to timelogger folder in your home directory and open the terminal 
by right clicking with your mouse and select "Open in Terminal" option from the right-click menu.

And run the installer file by using the following command and give your system password if prompted.

```
sh install.sh
```

``` Installer will get paused with text 'librdkafka installation path? [autodetect] :' Then please press enter to resume installation. ```
