import os
import requests
import sys


serverRootAddress = "http://192.168.0.9/timelogger/"
stationSoftwareFolder = "stationSoftware/"

fileNames = [
	"autoupdater.py",
	"code_processor.py",
	"code_scanner.py",
	"config.py",
	"main.py",
	"key_reader.py"
]

print("Checking remote version number")
try:
	r = requests.get(serverRootAddress + "scripts/server/remote_update.php", params={"request":"getConfigVersion"})
	resp = r.json()
	if resp["status"] != "success":
		print("Server returned error status");
		print(r.text)
		sys.exit()
except:
	print("comms error")
	sys.exit()

try:
	import configVersion
	localVersion = configVersion.versionNumber
except:
	localVersion = "none"

if resp["result"] == "":
	print("Error, no version code defined")
	sys.exit()
remoteVersion = resp["result"]

print("Remote version: {}   local version: {}".format(remoteVersion, localVersion))

if remoteVersion != localVersion:
	print("Updating local software from remote")
	for fileName in fileNames:
		remotePath = serverRootAddress + stationSoftwareFolder + fileName
		os.system("curl -o {} {}".format(fileName, remotePath)) # add an option here to overwrite files

	remotePath = serverRootAddress + stationSoftwareFolder + "wpa_supplicant.conf"
	os.system("sudo curl -o /etc/wpa_supplicant/wpa_supplicant.conf " + remotePath)

	f = open("configVersion.py","w")
	f.write("versionNumber='{}'".format(remoteVersion))
	f.close()
	os.system('sh -c "rm ./*.pyc"')

		
	print("Updated to version {}. Rebooting...".format(remoteVersion))
	os.system("reboot")
	
else:
	print("No update required")
	sys.exit()
