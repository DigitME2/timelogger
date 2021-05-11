'''
Created on 1 May 2019

@author: patrck

Read from event files in dev/input to get keyboard inputs
'''

import os
import threading
import Queue
import logging
import struct
import time #used for sleep 

import config

INPUT_FOLDER_PATH = "/dev/input/"

FORMAT ='llHHI'
EVENT_SIZE = struct.calcsize(FORMAT)

#temporary measure should get keycodes from the system
KEYCODES = config.key_codes

INPUT_FOLDER_PATH = '/dev/input/by-id/'

#how often should new inputs and stop requests be checked for, 
#this also checks for thread stop requests so should not be set
#large number as this will prevent programs from cleanly exiting
new_input_check_period = 0.5 


class NoKeyboard(Exception):
	pass

class KeyboardInputs(threading.Thread):
	''' read keyboard input and return in queue '''	
	_key_readers = {}

	def __init__(self, pause_value=True):
		"""
			params:
				[pause_value=True]- True> input writing to the queue, False> resume writing,
					default true, to begin reading call KeyboardInputs.paused(False)
		"""
		super(KeyboardInputs, self).__init__()
		self._key_queue = Queue.Queue()
		self._read = threading.Event()
		self._stop_request = threading.Event()
		self._pause_input = threading.Event()
		self._keyboard_connected_flag = threading.Event()

		#pause by default so new unwanted chars before required
		self.paused(pause_value)

	def stop(self): 
		"""Stop thread from running"""
		self._stop_request.set()
		logging.debug("Stopping reading from keyboard inputs...")

	def paused(self, pause_value = True):
		"""Set or clear flag to read keyboard input and place them on the queue.
			By default KeyboardInputs is paused when created

			params:
				[pause_value=True]- True> input writing to the queue, False> resume writing
		"""

		if pause_value:
			self._pause_input.set()
			logging.debug("Pausing reading keyboard input...")

		else:
			self._pause_input.clear()
			logging.debug("Starting reading keyboard input...")

	def check_for_inputs(self):
		"""Find ids for keyboard event files connected to machine

			return: list of event id file names
		"""
		if os.path.isdir(INPUT_FOLDER_PATH):
			all_inputs = os.listdir(INPUT_FOLDER_PATH)
			keyboard_input_ids = [event for event in all_inputs if (event[-3:]=='kbd')]
		else:
			keyboard_input_ids = []

		return keyboard_input_ids

	def stop_readers(self):
		"""close all input file connections"""
		
		for read_id, reader in zip(list(self._key_readers.keys()), 
								list(self._key_readers.values())):
			logging.debug("Stopping Keyboard Reader: {}".format(read_id) +\
				"\nYou may need to press any key on {} to exit!!!".format(read_id))
				
			reader.stop_reading()

		self._key_readers = []

	def start_readers(self, event_ids):
		"""start key reader threads"""
		for event in event_ids:
			try:
				reader = KeyReader(event, self._key_queue, self._pause_input)
				reader.start()
				self._key_readers[event] = reader
			except IOError:
				logging.error("Error starting reader")

	def keyboard_connected(self):
		"""Returns true if a keyboard is curenty connected

			If called directly after starting KeyboardInputs, 
			keyboard_connected may incorrectly return false. 
		"""
		return self._keyboard_connected_flag.is_set()
	
	def read_char(self, timeout=None):
		"""Returns a single character string read from keyboard input.

			If the input queue is empy it will return an empty string, 
			If no keyboard is attached it will raise a IOError

			Arguments: [timeout=None] if a posative number then blocks at most
				timeout seconds and then returns a blank string, 
				if None will return imediatly if no character is availible

			raise: If no keyboard is connected then will return a 
				key_reader.NoKeyboard Error
			"""

		if self._keyboard_connected_flag.is_set():
			if timeout == None and self._key_queue.empty():
				char = ''
			else:
				try:
					char = self._key_queue.get(True, timeout)
				except Queue.Empty:
					char = ''
		else:
			raise NoKeyboard("No Keyboard connected")

		return char
		

	def run(self):
		"""Read all inputs from keyboards and place asscii values on key_queue"""
		logging.debug("Keybord input reader started ...")


		while not self._stop_request.isSet():
						
			#remove KeyReaders that have stopped running
			for input_id, reader in zip(list(self._key_readers.keys()), 
									list(self._key_readers.values())):

				if not reader.is_alive():
					self._key_readers.pop(input_id)

			#check for all current keyboard inputs to machine
			inputs_found = self.check_for_inputs()

			#get list of current input id's
			current_inputs = self._key_readers.keys()

			#get list of ID's found that are not currently being read from
			newinputs = [newinput for newinput in inputs_found if (newinput not in current_inputs)]

			if len(newinputs) > 0:
				self.start_readers(newinputs)

			if len(self._key_readers) > 0:
				self._keyboard_connected_flag.set()
			else:
				self._keyboard_connected_flag.clear()

			if self._pause_input.is_set():
				while not self._key_queue.empty():
					try:
						self._key_queue.get(block=False)
					except Queue.Empty:
						break

			#wait before checking for new inputs again
			time.sleep(new_input_check_period)

		self.stop_readers()

class KeyReader(threading.Thread):
	

	def __init__(self, input_id, key_queue, pause_input):
		super(KeyReader, self).__init__()
		self._input_id = input_id #id of event file
		self._input_file = None #file connection
		self._key_queue = key_queue #queue to send items back
		self._stop_request = threading.Event() #stop flag
		self._pause_input = pause_input

		self.input_open() # open event file

	def input_open(self):
		"""open connection to input event file"""
		try:
			self._input_file = open(INPUT_FOLDER_PATH + self._input_id, 'rb')

			logging.debug("New keyboard input {}".format(self._input_id))
		except IOError as e:
			logging.error("Error opening input event file {}: {}".format(self._input_id, e))
			raise IOError("Error opening input event file {}: {}".format(self._input_id, e))


	def close_input(self):
		"""close input file connection"""
		try:
			if not self._input_file.closed:
				self._input_file.close()
		except IOError as e:
			logging.error("Error closing input event file {}: {}".format(self._input_id, e))

	def stop_reading(self):
		"""Stop thread from running"""
		self._stop_request.set()
		logging.info("Stopping reading from {}".format(self._input_id))

	def run(self):
		"""Read inputs from keyboard event file and place asscii values on key_queue"""

		while not self._stop_request.isSet():
			try:
				event = self._input_file.read(EVENT_SIZE)
			except (IOError, ValueError) as e:
				logging.error("keyboard Read Error: {}".format(e))
				self.stop_reading()
				break

			if not self._pause_input.is_set():
				(tv_sec, tv_usec, mtype, code, value) = struct.unpack(FORMAT, event)

				if mtype != 0 or code != 0 or value != 0:
					if value == 1 and code in KEYCODES:
						logging.debug("char read: {}".format(KEYCODES[code]))#####logging
						self._key_queue.put(KEYCODES[code])

		self.close_input()

if __name__ == "__main__":
	logging.basicConfig(level=logging.DEBUG)

	logging.info("Test script, press 0 to pause input or / to exit.")

	stopped = False


	key_queue = Queue.Queue()

	
	try:
		inputs = KeyboardInputs(key_queue)
		inputs.start()

		time.sleep(2)

		if inputs.keyboard_connected():
			inputs.paused(False)
			while not stopped:
				try:
					key = inputs.read_char()
				except NoKeyboard:
					key = ''				

				if key is not '':
					if key == '0':
						inputs.paused(True)
						time.sleep(30)
						inputs.paused(False)
					elif key == '/':
						stopped = True
						inputs.stop()
					else:
						print(">>" + key)
		else:
			logging.info("No Keyboard connected!!")

		logging.info("Stopping main")
	except KeyboardInterrupt:
		logging.info("KeyboardInterrupt, stopping")
	except Exception as e:
		logging.error(e)

	inputs.stop()
		
			
		
