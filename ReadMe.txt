!! Please note that this software installer targets a fresh installed Ubuntu 22.04 system. If you have any other server running on port:80 Please stop them using the examples,example- 'sudo systemctl stop nginx' and, 'sudo systemctl stop mysql' and so on. Also if any other our DigitME2 softwares are running please use the same like example way to stop them for a while and run install.sh. After this installation use 'sh ports_change.sh' to change this software server to run on port:81. And then please start other services by using examples like, example- 'sudo systemctl restart nginx' and, 'sudo systemctl restart mysql' and so on.

**Note: To copy & Paste the following commands in the ubuntu Terminal, Please copy here and paste with your mouse right-click, or press (ctrl+shift+v) in the terminal. **

To install Process Time Tracker Software:

1.   Open Terminal in ubuntu

by Pressing Ctrl+Alt+T at once

2.    Change the directory from home to Downloads with the following command (or) copy here and press (ctrl+shift+v) in the terminal to paste.

cd ~/Downloads/


3.    Change the working directory of the terminal to Timelogger by pressing the following
    command in the terminal (or) copy here and press (ctrl+shift+v) in the terminal to paste.

cd timelogger/

4.    Install the timelogger with the following command (or) copy here and press (ctrl+shift+v) in the terminal to paste.

sh install.sh

    --or--

sudo ./installer.sh

5.   Then system will ask for your password, enter your ubuntu system password for completing the installation. And while installing the ubuntu terminal will ask only once to press <ENTER> to continue, please press Enter Button in your keyboard then to proceed with the installation.

6.    To open the software please open the following link in your firefox browser or any web browser.
	
	http://localhost/timelogger/pages/overview_client.php


!!!!!!!!!!!!!!!For regular usage please ignore the below step!!!!!!!!!!!!!!!!!!!
***Note*** The following options are optional and can be used if only required. 
Else Please ignore the following ***Note***


!. Change this software running port from 80 to 81 with the following command.
 
	sh ports_change.sh
	
!!. After running the above file, To open the Process Time Tracker Software please open the following link in your Browser. 

	http://localhost:81/timelogger/pages/overview_client.php
	
!!!. To uninstall Process Time Tracker, Please use any one command from the following. But please be aware that you will loose all your data saved in this Process Time Tracker software will be lost after the uninstallation of this software and that data can never be retrieved.

	sh uninstall.sh      # Please don't do without making backup of your data.
	
	   --or--
	 
	sudo ./uninstaller.sh  # Please don't do without making backup of your data.
