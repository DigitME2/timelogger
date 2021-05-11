'''
Created on 30 Jan 2018

@author: richard
'''
import code_processor
import logging
from logging.handlers import RotatingFileHandler
import sys

logFormatter = logging.Formatter('%(asctime)s %(message)s')
rootLogger = logging.getLogger() #"admt_logger")
rootLogger.setLevel(logging.DEBUG)

fileHandler = RotatingFileHandler("/dev/null", maxBytes = 5*1024*1024, backupCount = 2)
fileHandler.setFormatter(logFormatter)
rootLogger.addHandler(fileHandler)

consoleHandler = logging.StreamHandler(sys.stdout)
consoleHandler.setFormatter(logFormatter)
rootLogger.addHandler(consoleHandler)

c = code_processor.CodeProcessor()
c.run()

if __name__ == '__main__':
	pass
	
