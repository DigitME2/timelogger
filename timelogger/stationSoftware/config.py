'''
Created on 5 Jan 2018

@author: richard

Configuration for the barcode scanner client
'''

serverTrackingURL = "http://192.168.0.9/timelogger/scripts/server/client_input.php"
heartbeatPeriod = 5
serverTimeout = 5
multipleUserClock = False #IF true recomended to extend timeoutPeriod and stateDisplayPeriod
multipleUseTimeOutError = False #If using multiple user, if true will trigger error after time out, if false will clock any users recognised up untill time out
recordQuantity = False

cameraResolution = (1024,768)
framesToGrabPerRead = 1 # allow multiple frames to be grabbed, to deal with a slow camera
codesFormatsToRead = ['QR-Code']

timeoutPeriod = 10 #seconds
quantitytimeoutPeriod = 15 #seconds
stateDisplayPeriod = 3 #seconds, time to show led indications before reset.

# ID codes may be any string, but must begin with this prefix
userIDCodePrefix = "user_"
projectIDCodePrefix = "pdrt_"
stoppageIDCodePrefix = "stpg_"

ledPinRed 	= 14
ledPinGreen 	= 15
ledPinBlue	= 18

buttonPin	= 17
debouncePeriod  = 0.05

screenAddress = 0x3C

key_codes = { 
	2:'1', 3:'2', 4:'3', 5:'4', 6:'5', 7:'6', 8:'7', 9:'8', 10:'9', 11:'0', 12:'-', 13:'+', 14:chr(8),
	28:'\n', 55:'*',
	71:'7', 72:'8', 73:'9', 74:'-', 
	75:'4', 76:'5', 77:'6', 78:'+', 
	79:'1', 80:'2', 81: '3', 82:'0', 
	83:'.', 96:'\n', 97:'', 98:'/', 99:'',
	111: chr(127)
	}
