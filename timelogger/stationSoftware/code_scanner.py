'''
Created on 14 Jul 2017

@author: richard
'''

import cv2
import config
import logging
from picamera.array import PiRGBArray
from picamera import PiCamera
from PIL import Image
import threading
import zbar
import sys
import time


class CodeScanner(object):
	'''
	Simple class that continually scans for QR codes. When a code is read,
	the data in it is placed on a queue, to be used by the main interface.
	'''


	def __init__(self, CodeQueue, CameraIndex = 0):
		'''
		Constructor
		'''
		self.camera = PiCamera()
		self.camera.resolution = config.cameraResolution
		self.camera.framerate = 30		
		self.rawCapture = PiRGBArray(self.camera, size=config.cameraResolution)
		time.sleep(0.1)
		self.cameraIndex = CameraIndex
		self.stopEvent = threading.Event()
		self.codeQueue = CodeQueue
		self.scanner = zbar.Scanner()
		self.pauseEvent = threading.Event()
		self.isPausedEvent  = threading.Event()

		
		
	def start(self):
		'''
		sets up and starts a new thread, which is responsible for running
		the camera and posting any codes read to a queue. Each newly read
		code is posted once.
		'''
		logging.debug("Starting scanner...")
		self.stopEvent.clear()
		t = threading.Thread(target=self.run)
		t.daemon = False;
		t.start()
		
		
	def stop(self): 
		self.stopEvent.set()
		logging.debug("Stopping scanner...")
		
	
	def pause(self):
		self.pauseEvent.set()
		while not self.isPausedEvent.is_set():
			pass
		
		
	def resume(self):
		self.pauseEvent.clear()
		while self.isPausedEvent.is_set():
			pass
		
		
	def run(self):
		logging.debug("Scanner started")
	
		prevCodes = []

		while not self.stopEvent.isSet():
			if self.pauseEvent.is_set():
				logging.debug("camera paused")
				self.isPausedEvent.set()
				while self.pauseEvent.is_set():
					pass
				logging.debug("camera resumed")
				self.isPausedEvent.clear()
			
			
			frame = None
			# Capture frame-by-frame.
			self.camera.capture(self.rawCapture, format="bgr", use_video_port=True)
			frame = self.rawCapture.array
			self.rawCapture.truncate(0)
				
			# Our operations on the frame come here
			gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
			
			image = Image.fromarray(gray)
		
			scannedCodes = self.scanner.scan(image)
			
					
			# build a set of newly visible QR codes
			if len(scannedCodes) > 0:
				scannedCodes = [{"data":symbol.data, "type":symbol.type} for symbol in scannedCodes]

				print(scannedCodes)
				
				logging.debug("scannedCodes {}".format(scannedCodes))
				logging.debug("prevCodes    {}".format(prevCodes))
				
				for scannedCode in scannedCodes:
					
					# skip empty codes and unwanted formats, and log
					# anything new
					if scannedCode['data'] == "":
						#print("Skipping code: No data")
						continue
					
					if not scannedCode['type'] in config.codesFormatsToRead:
						#print("Skipping code: Unwanted format ({})".format(scannedCode['type']))
						continue
					
					if not scannedCode['data'] in prevCodes:
						if self.codeQueue != None:
							self.codeQueue.put(scannedCode['data'])
							logging.debug("Add {} to queue".format(scannedCode['data']))
					else:
						logging.debug("Skip known code {}".format(scannedCode['data']))
						
				prevCodes = []
				for scannedCode in scannedCodes:
					prevCodes.append(scannedCode["data"])
			else:
				prevCodes = []


		# When everything done, release the capture
		logging.debug("scanner stopped")
		
		
if __name__ == "__main__":
	qr = CodeScanner(None, 0);
	qr.run();
		
