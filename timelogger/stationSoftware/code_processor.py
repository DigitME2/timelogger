'''
Created on 6 Feb 2018

@author: richard
'''

import Adafruit_SSD1306
import code_scanner
import config
import logging
from PIL import Image, ImageDraw, ImageFont
import Queue
import requests
import threading
import time
import traceback
import station_name
import subprocess
import sys

import key_reader
import configVersion


try:
	import squid
	import button
	squidLibAvailable = True
except:
	squidLibAvailable = False

ascRequestQueue = Queue.Queue() #queue for response from asynchronous server requests

class TimeOut(Exception):
	"""Exception to be called when a definded timeout period has expired"""
	pass

class CodeProcessor(object):
	'''
	Class which serves to process the codes read by one or more
	code_scanner objects. This class reads a user ID (identified by a
	prefix) and a job ID code, and sends them to the server. If this
	software is running on a Raspberry Pi (expected in most cases),
	a switch can be connected to the GPIO. This switch can be used to
	provide an input. If this switch is pressed, the job will be marked
	as being complete at this station. Pin specifications are in the
	config file. A seperate thread is used to control the outputs on the
	state indicator RGB LED.
	'''


	def __init__(self):
		'''
		Constructor
		'''

		logging.debug("Initialising code processor...")
		self.state = "idle"
		self.prevState = ""
		self.ledStateQueue = Queue.Queue()
		self.codeQueue = Queue.Queue()
		self.codeScanner = code_scanner.CodeScanner(self.codeQueue)
		self.codesSeen = set()
		self.currentCompanionIDs = []
		self.currentJobID = ""
		self.dispayMessage = ["","","",""]
		self.multiUserResponseCounter = {}
		self.jobFinishingStage = False
		self.timeoutEndTime = time.time()
				
		logging.debug("Attempting to create scanner...")
		self.codeScanner.start()
		logging.debug("Created scanner");
		
		self.ledIndicatorThread = threading.Thread(target=self.runLedThread)
		self.ledIndicatorThread.daemon = True
		self.ledIndicatorThread.start()
		
		if squidLibAvailable:
			self.finishStageButton = button.Button(config.buttonPin, config.debouncePeriod)
		else:
			self.finishStageButton = None

		if config.recordQuantity == True:
			#if recording quanitiy start keyboard reader
			self.keyboardInput = key_reader.KeyboardInputs()
			self.keyboardInput.start()
			
		self.jobFinishingStage = False
		
		self.stationName = station_name.name
		
		try:
			self.display = Adafruit_SSD1306.SSD1306_128_64(rst=None, i2c_address=config.screenAddress)
			self.display.begin()
			self.display.clear()
			self.display.begin()
#			for key in logging.Logger.manager.loggerDict:
#				print(key)

			logging.getLogger("Adafruit_I2C.Device.Bus.1.Address").setLevel(logging.WARNING)
			
		
		except:
			#if failed to connect and begin display then flash LED infinitly
			logging.debug("Failed to start display...")
			if squidLibAvailable:
				while True:
					try:
						self.ledStateQueue.put("error")
						time.sleep(1);
						self.ledStateQueue.put("reset")
						time.sleep(1);
					except KeyboardInterrupt:
						logging.info("Keyboard Interupt exiting...")
						
						#Attempt to stop threads before exiting
						try:						
							self.codeScanner.stop()
						except:
							logging.error("Failed to stop codeScanner when exiting");

						try:
							self.keyboardInput.stop()
						except:
							logging.error("Failed to stop keyboardInput when exiting");

						sys.exit()
		
		self.ipcmd = "hostname -I | cut -d\' \' -f1"
		self.ipAddress = subprocess.check_output(self.ipcmd, shell = True )
		self.errorMessage = ""
		
		logging.debug("Completed code processor initialisation")
	
	
	def runLedThread(self):
		ledState = "idle"
		logging.debug("Starting indiator LED thread")
		# LED states for each status (RGB, max=100)
		if squidLibAvailable:
			ledStates = {
				"newName":			squid.WHITE,
				"idle":				squid.WHITE,
				"markStageComplete":squid.BLUE,
				"codeAccumulator":	squid.GREEN,
				"error":			squid.RED,
				"clockedOn":		squid.BLUE,
				"clockedOff":		squid.PURPLE,
				"stoppageOn":		squid.BLUE,
				"stoppageOff":		squid.PURPLE,
				"singleUserSeen":	squid.OFF,
				"multiUserSeen":	squid.OFF,
				"multiUserResponce":squid.PURPLE,
				"stoppageSeen":		squid.OFF,
				"reset":			squid.OFF,
				"checkQuantity":    squid.PURPLE,
				"cancel":			squid.WHITE
			}
			
			logging.debug("Creating squid on pins {}(R) {}(G) {}(B)".format(
				config.ledPinRed, config.ledPinGreen, config.ledPinBlue
				))
			led = squid.Squid(config.ledPinRed, config.ledPinGreen, config.ledPinBlue)
		
		while True:
			ledState = self.ledStateQueue.get()
			logging.debug("Set ledState: {}".format(ledState))
			
			if squidLibAvailable:
				led.set_color(ledStates[ledState])


	'''
	Simple heartbeat function to test server access. Returns true if the server
	responds, false otherwise
	'''
	def heartbeat(self):
		try:
			logging.debug("sending heartbeat")
			postData = {"request":"heartbeat", "stationId":self.stationName, "version":configVersion.versionNumber}
			response = requests.get(
				config.serverTrackingURL, 
				params=postData, 
				timeout=config.serverTimeout
				)
			responseJson = response.json()
			if responseJson["status"] != "success":
				logging.error("Error response: {}".format(responseJson["result"]))
				return False;
			logging.debug("server replied")
			self.ipAddress = subprocess.check_output(self.ipcmd, shell = True )
			return True
		except:
			logging.error("No response/other error")
			return False
		
		
	'''
	Checks with the server to find out if the station has been renamed. If it has,
	retreive the new name and update the station_name file and local name.
	'''
	def checkForNewName(self):
		logging.debug("checking for name change")
		postData = {"request":"checkForNameUpdate", "stationId":self.stationName}
		response = requests.get(
			config.serverTrackingURL, 
			params=postData, 
			timeout=config.serverTimeout
			)
		responseJson = response.json()
		if responseJson["status"] != "success":
			logging.error("Error response: {}".format(responseJson["result"]))
			return
		
		if responseJson["result"] == "noChange":
			logging.debug("No change required")
		else:
			newName = responseJson["result"]
			logging.debug("Name change required. New name is {}".format(newName))
			self.stationName = newName
			
			f = open("station_name.py","w");
			f.write("name = '{}'".format(self.stationName))
			f.close()

			postData = {"request":"completeNameUpdate", "stationId":self.stationName}
			response = requests.get(
				config.serverTrackingURL, 
				params=postData, 
				timeout=config.serverTimeout
				)

			self.state="newName"

			logging.debug("Name change complete")

		
	def updateStatusDisplay(self):
		font = ImageFont.truetype(font="DejaVuSansMono.ttf", size=15) 
		image = Image.new('1', (self.display.width, self.display.height))
		width = self.display.width
		height = self.display.height
		draw = ImageDraw.Draw(image)
		draw.rectangle((0,0,width,height),outline=0,fill=0)
		
		if self.state == "idle" or self.state == "newName":
			draw.text((0,0), 			self.stationName, font=font, fill=255)
			draw.text((0,height/3), 	"Scan a QR code...", font=font, fill=255)
			draw.text((0,2*height/3), 	self.ipAddress, font=font, fill=255)
	
		elif self.state == "markStageComplete":
			draw.text((0,0), 			"Ready to mark", font=font, fill=255)
			draw.text((0,height/3), 	"stage complete", font=font, fill=255)
	
		elif self.state == "codeAccumulator":
			draw.text((0,0), 			self.dispayMessage[0], font=font, fill=255)
			draw.text((0,height/3), 	self.dispayMessage[1], font=font, fill=255)
			draw.text((0,2*height/3),	self.dispayMessage[2], font=font, fill=255)
			
		elif self.state == "singleUserSeen":
			draw.text((0,0), 		"Processing...", font=font, fill=255)

		elif self.state == "multiUserSeen":
			draw.text((0,0), 		"Processing...", font=font, fill=255)

		elif self.state == "stoppageSeen":
			draw.text((0,0), 		"Processing...", font=font, fill=255)
			
		elif self.state == "error":
			draw.text((0,0), 			"ERROR", font=font, fill=255)
			draw.text((0,height/3), 	self.errorMessage, font=font, fill=255)
			draw.text((0,2*height/3), 	self.ipAddress, font=font, fill=255)
			
		elif self.state == "clockedOn":
			draw.text((0,0), 			"Clocked ON", font=font, fill=255)
			draw.text((0,height/3), 	(str)(self.currentJobID), font=font, fill=255)
			
		elif self.state == "clockedOff":
			draw.text((0,0), 			"Clocked OFF", font=font, fill=255)
			draw.text((0,height/3), 	(str)(self.currentJobID), font=font, fill=255)

		elif self.state == "multiUserResponce":
			draw.text((0,0), 			"Recorded:", font=font, fill=255)
			draw.text((0,height/4), 	self.dispayMessage[0], font=font, fill=255)
			draw.text((0,2*height/4), 	self.dispayMessage[1], font=font, fill=255)
			draw.text((0,3*height/4), 	self.dispayMessage[2], font=font, fill=255)
			
		elif self.state == "stoppageOn":
			draw.text((0,0), 			"Stoppage ON", font=font, fill=255)
			draw.text((0,height/3), 	(str)(self.currentJobID), font=font, fill=255)
			
		elif self.state == "stoppageOff":
			draw.text((0,0), 			"Stoppage OFF", font=font, fill=255)
			draw.text((0,height/3), 	(str)(self.currentJobID), font=font, fill=255)

		elif self.state == "checkQuantity":
			draw.text((0,0), 			"Clocked Off", font=font, fill=255)
			draw.text((0,height/3), 	self.dispayMessage[1], font=font, fill=255)	
			draw.text((0,2*height/3), 	self.dispayMessage[2], font=font, fill=255)

		elif self.state == "cancel":
			draw.text((0,0), 			self.stationName, font=font, fill=255)
			draw.text((0,height/3), 	"CANCELED!", font=font, fill=255)	
			draw.text((0,2*height/3), 	"", font=font, fill=255)
	
		self.display.image(image)
		self.display.display()
	
	
	def run(self):
		'''
		Main loop, which waits for a pair of codes (user ID and job ID),
		then sends them to the server. Implemented as a simple state machine.
		'''
		stateTimeout = time.time()
		nextHeartbeatTime = time.time()
		waitingForServer = False
		while(True):
			try:
				if time.time() >= nextHeartbeatTime:
					nextHeartbeatTime = time.time() + config.heartbeatPeriod
					serverAvailable = self.heartbeat()
					if not serverAvailable:
						self.state = "error"
						self.errorMessage = "No server"
						waitingForServer = True
					else:
						self.checkForNewName()
						waitingForServer = False


				if self.prevState != self.state:
					self.prevState = self.state
					self.ledStateQueue.put(self.state)
					self.updateStatusDisplay()	
					logging.debug("New state: {}\n".format(self.state))


				# skip all further input until the server becomes available.
				if waitingForServer:
					continue

				if(self.state == "newName"):
					self.state = "idle"
				
				
				if(self.state == "idle"):
					self.updateStatusDisplay()					
					if(self.finishStageButtonPressed()):
						self.state = "markStageComplete"
						self.jobFinishingStage = True
					
					if not self.codeQueue.empty():
						self.state = "codeAccumulator"	
				
				
				
				elif self.state == "markStageComplete":
					stateTimeout = time.time() + config.timeoutPeriod
					while(True):
						if not self.codeQueue.empty():
							self.state = "codeAccumulator"
							break
						elif time.time() > stateTimeout:
							self.state = "error"
							break
				
				
				
				elif self.state == "codeAccumulator":
					self.accumulateCodes()
				
				
				
				elif self.state == "singleUserSeen":
					# send data to server, and await response
					jobState = "workInProgress"
					if self.jobFinishingStage:
						jobState = "stageComplete"
						
					payload = {
					"request":"clockUser",
					"userId":self.currentCompanionIDs[0],
					"jobId":self.currentJobID,
					"stationId":self.stationName,
					"jobStatus":jobState
					}
					
					try:
						response = requests.get(config.serverTrackingURL, 
												params=payload, 
												timeout=config.serverTimeout)
						logging.debug("Server response: {}".format(response))
						logging.debug(response._content)
						responseJson = response.json()
						
						if responseJson["status"] == "success":
							logging.debug("recordQuantity: {}, result: {}" \
								.format(config.recordQuantity, responseJson["result"]))
							if (config.recordQuantity == True and 
									responseJson["result"]["state"] == "clockedOff"):
								self.state = "checkQuantity"
								self.currentLogRef = responseJson["result"]["logRef"]
							else:
								self.state = responseJson["result"]["state"]
						else:
							self.state = "error"
							if len(responseJson["result"]) <= 14:
								self.errorMessage = responseJson["result"]
							
					except requests.exceptions.ConnectTimeout:
						logging.debug("Timeout when trying to connect to {}" \
							.format(config.serverTrackingURL))
						self.state = "error"
						self.errorMessage = "conn time"
						
					except requests.exceptions.ConnectionError:
						logging.debug("ConnectionError when trying to connect to {}" \
							.format(config.serverTrackingURL))
						self.state = "error"
						self.errorMessage = "conn err"


				elif self.state == "multiUserSeen":
					# send data to server, and await response
					self.multiUserResponseCounter = {"clockedOn": 0, "clockedOff":0, "error":0}

					jobState = "workInProgress"
					if self.jobFinishingStage:
						jobState = "stageComplete"					

					for companion in self.currentCompanionIDs:
						payload = {
						"request":"clockUser",
						"userId":companion,
						"jobId":self.currentJobID,
						"stationId":self.stationName,
						"jobStatus":jobState
						}

						a = threading.Thread(target=asc_request, args=(payload,));
						a.start();

					threadTimeout = time.time() + (config.stateDisplayPeriod * 3)

					for companion in self.currentCompanionIDs:
						while ascRequestQueue.empty():
							pass
						response = ascRequestQueue.get()
						
						logging.debug("Thread Return: {}".format(response))
						if response["serverResponce"]["status"] == "success":
							
							if response["serverResponce"]["result"]["state"] in self.multiUserResponseCounter:
								self.multiUserResponseCounter[response["serverResponce"]["result"]["state"]] = self.multiUserResponseCounter[response["serverResponce"]["result"]["state"]] + 1
							else:
								self.multiUserResponseCounter["error"] = \
									self.multiUserResponseCounter["error"] + 1
						else:
							self.multiUserResponseCounter["error"] = \
								self.multiUserResponseCounter["error"] + 1

						if(time.time() > threadTimeout):
							logging.debug("Thread Time Out!")
							self.state = "error"
							self.errorMessage = "error conn th"
							break

					if (self.multiUserResponseCounter["clockedOn"] == 0 and
							self.multiUserResponseCounter["error"] == 0 and
							self.multiUserResponseCounter["clockedOff"] == 1 and
							config.recordQuantity == True):
						#if a single user has clocked off & recording qunatity
						self.state = "checkQuantity"
						self.currentLogRef = response["serverResponce"]["result"]["logRef"]
					else:
						self.state = "multiUserResponce"

				elif self.state == "multiUserResponce":

					if (self.multiUserResponseCounter["clockedOn"] == 0 and
							self.multiUserResponseCounter["clockedOff"] == 0):
						self.ledStateQueue.put("error")
#					elif (self.multiUserResponseCounter["error"] == 0 and
#							self.multiUserResponseCounter["clockedOff"] == 0):
#						self.ledStateQueue.put("clockedOn")

					displayLables = {"clockedOn":"Clocked On", 
									"clockedOff":"Clocked Off", 
									"error":"Error"}
					
					displayValues = []
					for key in self.multiUserResponseCounter:
						if self.multiUserResponseCounter[key] != 0:
							displayValues.append(
								displayLables[key] + " " + 
								str(self.multiUserResponseCounter[key]))
						
					logging.debug("displayValues: {}".format(displayValues))
					self.setDisplayMessages(values=displayValues, clear=True)
					self.updateStatusDisplay()

					stateTimeout = time.time() + config.stateDisplayPeriod

					logging.debug("waiting for timeout...")
					while(time.time() < stateTimeout):
						pass
					logging.debug("done");

					self.resetVariables()
					
					self.state = "idle"

				
				elif self.state == "stoppageSeen":
					# send data to server, and await response
					jobState = "unresolved"
					if self.jobFinishingStage:
						jobState = "resolved"

					payload = {
					"request":"recordStoppage",
					"stoppageId":self.currentCompanionIDs[0],
					"jobId":self.currentJobID,
					"stationId":self.stationName,
					"jobStatus":jobState
					}
					
					try:
						response = requests.get(
							config.serverTrackingURL, 
							params=payload, 
							timeout=config.serverTimeout)
						logging.debug("Server response: {}".format(response))
						logging.debug(response._content)
						responseJson = response.json()
						
						if responseJson["status"] == "success":
							self.state = responseJson["result"]
						else:
							self.state = "error"
							if len(responseJson["result"]) <= 14:
								self.errorMessage = responseJson["result"]
							
					except requests.exceptions.ConnectTimeout:
						logging.debug("Timeout when trying to connect to {}" \
							.format(config.serverTrackingURL))
						self.state = "error"
						self.errorMessage = "conn time"
						
					except requests.exceptions.ConnectionError:
						logging.debug("ConnectionError when trying to connect to {}" \
							.format(config.serverTrackingURL))
						self.state = "error"
						self.errorMessage = "conn err"

				elif self.state == "checkQuantity":
					logging.debug("checkQuantity")

					self.checkQuantity()
						
				# display the state change. While this is being shown, clean up any extra codes
				elif (self.state == "error" or
						self.state == "clockedOn" or
						self.state == "clockedOff" or
                        self.state == "stoppageOn" or
                        self.state == "stoppageOff" or 
						self.state == "cancel"):

					self.ledStateQueue.put(self.state)
					logging.debug("New state: {}\n".format(self.state))	

					# state change will be picked up by LED thread automatically
					stateTimeout = time.time() + config.stateDisplayPeriod		

					logging.debug("waiting for timeout...")
					while(time.time() < stateTimeout):
						pass
					logging.debug("done");

					self.resetVariables()
					
					self.state = "idle"
						
				else:                    
					self.state = "error"
					self.errorMessage = "Internal"
			
			except KeyboardInterrupt:
				self.codeScanner.stop()
				self.keyboardInput.stop()
				self.state = None
				self.updateStatusDisplay()
				sys.exit()
				
			
			except:
				self.state = "error"
				self.errorMessage = "terminated"
				self.updateStatusDisplay()
				print traceback.print_exc()

	def resetVariables(self):
		self.currentJobID = ""
		self.currentCompanionIDs = []
		self.currentLogRef = None
		self.codesSeen.clear()
		self.dispayMessage = ["","","",""]
		self.jobFinishingStage = False
		self.errorMessage = ""

	def checkQuantity(self):
		"""checkQuantity State main processing, 
			read user numerical QTY input and send to server if not blank"""

		quantityString = ''

		if not self.keyboardInput.keyboard_connected():
			logging.debug("Quantity- No Keyboard!")
			self.state = "clockedOff"
		else:
			self.setDisplayMessages(
				[self.currentJobID, "Enter Quantity?"], 
				clear=True)
			self.updateStatusDisplay()

			#to be displayed once a character has been input
			self.dispayMessage[1] = "Quantity:"

			try:
				quantityString = self.read_numerical_input(
					display_line=2,
					timeout_period=config.quantitytimeoutPeriod,
					key_extend_timeout=True,
					max_length=9
					)

			except key_reader.NoKeyboard:					
				logging.debug("Error Reading from Keyboard Input")
				self.state = "error"
				self.errorMessage = "No Keypad!!"

			except TimeOut:
				logging.debug("Timeout while waiting for quantity")
				self.state = "error"
				self.errorMessage = "Timeout"


			
			if (self.state != "error" and
					len(quantityString) > 0 and
					quantityString.isdigit()):
				payload = {
				"request":"recordNumberCompleted",
				"logRef":self.currentLogRef,
				"numberCompleted":int(quantityString)
				}

				logging.debug("Recording Quantity of {} for log record {}" \
					.format(quantityString, self.currentLogRef))
				
				try:
					response = requests.get(
						config.serverTrackingURL,
						params=payload, 
						timeout=config.serverTimeout)

					logging.debug("Server response: {}".format(response))
					logging.debug(response._content)
					responseJson = response.json()
					
					if responseJson["status"] == "success":
						self.state = "clockedOff"
					else:
						self.state = "error"
						
				except requests.exceptions.ConnectTimeout:
					logging.debug(
						"Timeout when trying to connect to {}" \
						.format(config.serverTrackingURL))
					self.state = "error"
					self.errorMessage = "conn time"
					
				except requests.exceptions.ConnectionError:
					logging.debug(
						"ConnectionError when trying to connect to {}" \
						.format(config.serverTrackingURL))
					self.state = "error"
					self.errorMessage = "conn err"
			elif quantityString == '':
				self.state = "clockedOff"

		#if the state is still check quantity after processing
		#then an error must have occured
		if self.state == "checkQuantity":
			self.state = "error"
			self.errorMessage = "internal err"
	
	def finishStageButtonPressed(self):
		'''
		If possible (depends on hardware), indicates if the button to mark
		the job as finishing at the state has been pressed. If the required
		hardware isn't available, this function always returns false.
		'''
		if self.finishStageButton == None: 
			return False
		
		return self.finishStageButton.is_pressed()	
		

	
	def getCode(self):
		'''
		Retrieves a code from the queue, determines if it represents
		a user or a job, and returns this information
		'''
		code = self.codeQueue.get()
		
		if(code[:len(config.userIDCodePrefix)] == config.userIDCodePrefix):
			codeType = "userID"
		elif(code[:len(config.stoppageIDCodePrefix)] == config.stoppageIDCodePrefix):
			codeType = "stoppageID"
		elif(code[:len(config.projectIDCodePrefix)] == config.projectIDCodePrefix):
			codeType = "jobID"
		else:
			codeType = "jobID"
			
		return codeType, code
	
			
			
	def accumulateCodes(self):
		'''Accumulate a set of valid QR Codes until a complete combination is found'''

		codeAccumulatorTimeout = time.time() + config.timeoutPeriod;
		codeTypesSeen = set()

		ledTimeOut = 0
		jobIdMissing = False

		idMissingFlag = 0

		while(self.state == "codeAccumulator"):
			if(ledTimeOut != 0 and time.time() > ledTimeOut):
				ledTimeOut = 0
				self.ledStateQueue.put("codeAccumulator")

			if not self.codeQueue.empty():
				codeInfo = self.getCode()
				codeType = codeInfo[0]

				if codeInfo not in self.codesSeen:
					#check that incorrect numbers of the same type of code arn't being added
					if codeType == "jobID" and "jobID" in codeTypesSeen:
						self.state = "error"
						self.errorMessage = "Two Job Ids"

					elif codeType == "productID" and "productID" in codeTypesSeen:
						self.state = "error"
						self.errorMessage = "Two Products"

					elif codeType == "stoppageID" and "stoppageID" in codeTypesSeen:
						self.state = "error"
						self.errorMessage = "Two Stoppages"

					elif (not config.multipleUserClock and 
							codeType == "userID" and "userID" in codeTypesSeen):
						self.state = "error"
						self.errorMessage = "Two Users"

					#check a user ID has not been entered with a stoppage ID
					elif ((codeType == "userID" or "userID" in codeTypesSeen) and 
							(codeType == "stoppageID" or "stoppageID" in codeTypesSeen)):
						self.state = "error"
						self.errorMessage = "Stoppage+User"

					else:
						logging.debug("-------------Valid Code Seen-----------------")
						codeAccumulatorTimeout = time.time() + config.timeoutPeriod;

						#Add code and check if any action can be taken with the combination
						self.codesSeen.add(codeInfo)
						codeTypesSeen.add(codeInfo[0])

						logging.debug("codesSeen: {}".format(self.codesSeen))
						logging.debug("codesTypesSeen: {}".format(codeTypesSeen))					 

						if "userID" in codeTypesSeen and "jobID" in codeTypesSeen:
							if not config.multipleUserClock:
								logging.debug("-------------Clocking Single User-----------------")
								self.state = "singleUserSeen"
						
						elif "stoppageID" in codeTypesSeen and "jobID" in codeTypesSeen:
							logging.debug("-------------Recording Stoppage-----------------")
							self.state = "stoppageSeen"

						if config.multipleUserClock:
							ledTimeOut = time.time() + 0.5
							self.ledStateQueue.put("clockedOn")

							idMissingFlag = 0
							logging.debug("ID missing button press: {}".format(idMissingFlag))

							self.dispayMessage[0] = "Scan Another:"
							if codeType == "jobID":
								self.dispayMessage[1] = codeInfo[1]
								if jobIdMissing == True:
									jobIdMissing = False
									self.dispayMessage[2] = ""
							else:
								self.dispayMessage[2] = codeInfo[1]
						else:
							self.setDisplayMessages(
								values=["Scan a second", "QR code", codeInfo[1]], 
								clear=True)	

						self.updateStatusDisplay()			
					
			if config.multipleUserClock and self.finishStageButtonPressed():
				if "jobID" in codeTypesSeen and "userID" in codeTypesSeen:
					logging.debug("-------------Clocking Multiple User-----------------")
					self.state = "multiUserSeen"
				else:
					ledTimeOut = time.time() + 0.5
					self.ledStateQueue.put("error")												

					if not "jobID" in codeTypesSeen:	
						jobIdMissing = True

					idMissingFlag = idMissingFlag + 1
					logging.debug("ID missing button press: {}".format(idMissingFlag))

					if idMissingFlag >= 3:
						logging.debug("ID missing button press: {}".format(idMissingFlag))
						self.state = "cancel"
					elif idMissingFlag > 1:
						self.dispayMessage[2] = "Cancel?"
						ledTimeOut = 0;
						self.updateStatusDisplay()
					else:
						self.dispayMessage[2] = "ID missing"
						self.updateStatusDisplay()	

			elif time.time() > codeAccumulatorTimeout:
				if (config.multipleUserClock and 
						"jobID" in codeTypesSeen and 
						"userID" in codeTypesSeen):
					logging.debug("-------------Clocking Multiple User-----------------")
					if config.multipleUseTimeOutError:
						self.state = "error"
						self.errorMessage = "timed out"
					else:
						self.state = "multiUserSeen"
				else:
					self.state = "error"
					self.errorMessage = "timed out"

		if self.state != "error" and self.state != "cancel":
			self.sortQRCodes()
			logging.debug("Job ID: {}".format(self.currentJobID))
			logging.debug("Companion IDs: {}".format(self.currentCompanionIDs))
	
	def sortQRCodes(self):
		'''Sort a set of QR codes into a jobID and companion ID (User/ Stoppage)'''
		
		for code in self.codesSeen:
			if code[0] == "jobID" or code[0] == "productID":
				self.currentJobID = code[1]
			elif code[0] == "userID" or code[0] == "stoppageID":
				self.currentCompanionIDs.append(code[1])
			else:
				logging.warning("UNKNOWN ID TYPE")

		if self.currentJobID == "" or len(self.currentCompanionIDs) == 0:
			self.state = "error"
			self.errorMessage = "ID missing"

	def setDisplayMessages(self, values=[], clear=False):
				
		if len(values) > 4:
			values = values[0:3]
			logging.warning("setDisplayMessages: number of values passed greater than 4")

		if clear == True:
			self.dispayMessage = values + ([""]*(4-len(values)))
		else:
			self.dispayMessage = values + self.dispayMessage[len(values):4]

	def read_numerical_input(self, display_line=None, timeout_period=0, 
							key_extend_timeout=True, max_length=0):
		"""Read a numerical string input from keyboard

			[display_line=None [timeout_period=0 [[key_extend_timeout=True] max_length=0]]]
			Parameters:
				display_line=None: the line of the display to show the
					user input as it is recived. If none it will not display.
				timeout_period=0: if greater than 0 will raise TimeOut error
					if no new line found before end of period. Min 0.1s
				key_extend_timeout=True: if true will extend when a timeout
					will occur by timeout_period every time a key press is 
					detected.
				max_length=0: if greater than 0 will limit the amount the
					lenght of input user can provide 
		"""

		#request characters from keyboard
		self.keyboardInput.paused(False)
			
		if timeout_period > 0:
			#if timeout period provide
			read_Timeout = time.time() + timeout_period
		else:
			#do not time out
			quantityTimeout = 0

		quantityString = ''
		newChar = ''
		while newChar!='\n':
			
			if newChar != '':							
				logging.debug("main newChar" + str(newChar))

				if newChar == chr(8) or newChar == chr(127):
					#if delete or back space remove last char
					quantityString = quantityString[:-1]

				elif (newChar.isdigit() and
						max_length!=0 and
						len(quantityString)<max_length):
					#if a number and new char will not exceed the max length
					quantityString = quantityString + newChar
					

				if display_line is not None:
					#update screen display message
					self.dispayMessage[display_line] = quantityString
					self.updateStatusDisplay()

				logging.debug("Current Quantity: " + quantityString)

				if timeout_period > 0 and key_extend_timeout:
					#if requested, extend timeout as a key has been pressed
					read_Timeout = time.time() + timeout_period		

			if timeout_period > 0 and time.time() > read_Timeout:
				self.keyboardInput.paused(True)
				raise TimeOut

			newChar = self.keyboardInput.read_char(0.1)

		#stop characters being added to buffer
		self.keyboardInput.paused(True)

		return quantityString

def asc_request(payload):
		
	try:
		response = requests.get(
			config.serverTrackingURL, 
			params=payload, 
			timeout=config.serverTimeout)
		logging.debug("Server response: {}".format(response))
		logging.debug(response._content)
		responseJson = {"userID":payload["userId"], "serverResponce":response.json()}

		ascRequestQueue.put(responseJson)

	except requests.exceptions.ConnectTimeout:
		logging.debug("THREAD Timeout when trying to connect to {}".format(config.serverTrackingURL))
		ascRequestQueue.put({"userID":payload["userId"], "serverResponce":{"error": "conn time"}})
		
	except requests.exceptions.ConnectionError:
		logging.debug("THREAD ConnectionError when trying to connect to {}" \
			.format(config.serverTrackingURL))
		ascRequestQueue.put({"userID":payload["userId"], "serverResponce":{"error": "conn err"}})
