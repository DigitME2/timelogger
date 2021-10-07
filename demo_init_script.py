#!/usr/bin/python3

# Script to load a defined dataset into the timelogger database, for demo purposes. Wipes existing data first.
# Note that jobs may only ever move forward through the list of stations. Some may by skipped, but a job
# can never go backwards, e.g. from assembly to painting.
#
# WARNING: THIS WILL ERASE ALL DATA CURRENTLY IN THE SYSTEM

import pymysql
import requests
import random

hostname = "localhost"
dbPort = 3306
serverPort = 80

def secondsToTimeStr(totalSeconds):
	h = totalSeconds // 3600
	totalSeconds -= (3600 * h)
	m = totalSeconds // 60
	s = totalSeconds - (60 * m)
	return "{:02}:{:02}:{:02}".format(h,m,s)

userNames = ["Alice","Bob","Charlotte","David","Emily","Felix"]
# note all times on jobs are in hours. This is converted to seconds as required
jobs = [
			{
				"id":"WO33652",
				"custName":"ABC Construction",		
				"desc":"Modular frame assemblies",	
				"numUnits":10,	
				"totalParts":80,  
				"creationOffset":-16, 
				"dueOffset":-8, 
				"route":"No Paint",				
				"cost":90000, 
				"priority":2,
				"times":{
					"Cutting":18,
					"Welding":12,
					"Painting":0,
					"Assembly":8.5,
					"QC":4.25,
					"Shipping":15
				}
			},
			{
				"id":"WO33653", 
				"custName":"Willson Logistics",	
				"desc":"Packing noodles",			
				"numUnits":1,	
				"totalParts":100, 
				"creationOffset":-16, 
				"dueOffset":-7,
				"route":"Main Production Route",
				"cost":3000,
				"priority":1,
				"times":{
					"Cutting":12,
					"Welding":1.5,
					"Painting":2.5,
					"Assembly":1,
					"QC":0.5,
					"Shipping":2.25
				}
			},
			{
				"id":"WO33654", 
				"custName":"Bakewell Cakes", 		
				"desc":"Racking",					
				"numUnits":3,	
				"totalParts":15,  
				"creationOffset":-14, 
				"dueOffset":2,
				"route":"No Paint",
				"cost":65000, 
				"priority":3,
				"times":{
					"Cutting":1.5,
					"Welding":2.5,
					"Painting":0,
					"Assembly":1.25,
					"QC":0.25,
					"Shipping":2.5
				}
			},
			{
				"id":"WO33655", 
				"custName":"Greendale",		 	
				"desc":"Tables x 10",				
				"numUnits":10,	
				"totalParts":80,  
				"creationOffset":-13, 
				"dueOffset":-5,  
				"route":"Main Production Route",	
				"cost":45000, 
				"priority":2,
				"times":{
					"Cutting":1,
					"Welding":6,
					"Painting":3.5,
					"Assembly":2,
					"QC":1,
					"Shipping":2.75
				}
			},
			{
				"id":"WO33656",
				"custName":"Purple Boxes",
				"desc":"Warehouse shelving",
				"numUnits":50,  
				"totalParts":500, 
				"creationOffset":-13, 
				"dueOffset":3,
				"route":"No Paint",
				"cost":23000, 
				"priority":2,
				"times":{
					"Cutting":2,
					"Welding":5,
					"Painting":0,
					"Assembly":3.5,
					"QC":2.25,
					"Shipping":1
				}
			},
			{
				"id":"WO33657", 
				"custName":"Smith and Johnson",	
				"desc":"Bespoke metalwork parts",	
				"numUnits":2,  	
				"totalParts":6,   
				"creationOffset":-12, 
				"dueOffset":7,  
				"route":"Short Route",				
				"cost":72000, 
				"priority":3,
				"times":{
					"Cutting":3,
					"Welding":8.5,
					"Painting":0,
					"Assembly":0,
					"QC":3,
					"Shipping":3
				}
			},
			{
				"id":"WO33658", 
				"custName":"P4 Computer Supplies", 
				"desc":"Detector system",			
				"numUnits":1, 	
				"totalParts":1,   
				"creationOffset":-11, 
				"dueOffset":-9,   
				"route":"Main Production Route",	
				"cost":83000, 
				"priority":1,
				"times":{
					"Cutting":4,
					"Welding":2,
					"Painting":6,
					"Assembly":11,
					"QC":2,
					"Shipping":3
				}
			},
			{
				"id":"WO33659", 
				"custName":"Proton Fire Systems", 	
				"desc":"Case assemblies",			
				"numUnits":10,  
				"totalParts":100, 
				"creationOffset":-7,  
				"dueOffset":1,
				"route":"Main Production Route",
				"cost":79000, 
				"priority":3,
				"times":{
					"Cutting":2,
					"Welding":1.5,
					"Painting":0.5,
					"Assembly":6,
					"QC":1.5,
					"Shipping":1
				}
			},
			{
				"id":"WO33660", 
				"custName":"Paris & Co.", 			
				"desc":"Jetpack harness parts",		
				"numUnits":1,  	
				"totalParts":53,  
				"creationOffset":-6,  
				"dueOffset":1, 	   
				"route":"Main Production Route",	
				"cost":10000, 
				"priority":2,
				"times":{
					"Cutting":1.5,
					"Welding":2.5,
					"Painting":1.25,
					"Assembly":6.5,
					"QC":10,
					"Shipping":1.5
				}
			},
			{
				"id":"WO33661",
				"custName":"Empire Supplies", 		
				"desc":"Bottling machine",			
				"numUnits":1,  	
				"totalParts":150, 
				"creationOffset":-6,  
				"dueOffset":5,
				"route":"Main Production Route",	
				"cost":50000, 
				"priority":4,
				"times":{
					"Cutting":3,
					"Welding":7,
					"Painting":1,
					"Assembly":8,
					"QC":2.5,
					"Shipping":3
				}
			},
			{
				"id":"WO33662", 
				"custName":"Ransom, Willis and Co",
				"desc":"Desk chairs",				
				"numUnits":5,  	
				"totalParts":50,  
				"creationOffset":-6,  
				"dueOffset":+3,
				"route":"Main Production Route",	
				"cost":70000, 
				"priority":3,
				"times":{
					"Cutting":2.5,
					"Welding":8,
					"Painting":0,
					"Assembly":10,
					"QC":3,
					"Shipping":2.5
				}
			},
			{
				"id":"WO33663", 
				"custName":"Burns Farm", 			
				"desc":"Custom wheel mountings",	
				"numUnits":4, 	
				"totalParts":4,   
				"creationOffset":-5,  
				"dueOffset":+7,
				"route":"Main Production Route",	
				"cost":20000, 
				"priority":2,
				"times":{
					"Cutting":0.75,
					"Welding":2,
					"Painting":8,
					"Assembly":3,
					"QC":1.75,
					"Shipping":1.75
				}
			},
			{
				"id":"WO33664", 
				"custName":"Hall Detectors", 		
				"desc":"Sensor casings",
				"numUnits":10,  
				"totalParts":60,  
				"creationOffset":-4,  
				"dueOffset":-2,
				"route":"Main Production Route",	
				"cost":70000, 
				"priority":4,
				"times":{
					"Cutting":2,
					"Welding":2,
					"Painting":2,
					"Assembly":1,
					"QC":1,
					"Shipping":1
				}
			},
			{
				"id":"WO33665", 
				"custName":"Wandas Wonders", 		
				"desc":"Custom moulds",				
				"numUnits":5,  	
				"totalParts":5,   
				"creationOffset":-3,  
				"dueOffset":9,
				"route":"Main Production Route",	
				"cost":24000, 
				"priority":4,
				"times":{
					"Cutting":7.5,
					"Welding":18,
					"Painting":3,
					"Assembly":12,
					"QC":6,
					"Shipping":9
				}
			},
			{
				"id":"WO33666",
				"custName":"Hearthstone Windows", 	
				"desc":"Doors - steel",				
				"numUnits":16,  
				"totalParts":32,  
				"creationOffset":-2,  
				"dueOffset":-1, 
				"route":"Main Production Route",	
				"cost":22000, 
				"priority":2,
				"times":{
					"Cutting":2.5,
					"Welding":20,
					"Painting":0,
					"Assembly":5,
					"QC":1.25,
					"Shipping":5
				}
			},
			{
				"id":"WO33667", 
				"custName":"Joes pharmacy", 		
				"desc":"Projectors",				
				"numUnits":3,  	
				"totalParts":81,  
				"creationOffset":-2,  
				"dueOffset":7, 	
				"route":"Main Production Route",	
				"cost":53000, 
				"priority":3,
				"times":{
					"Cutting":2.5,
					"Welding":20,
					"Painting":0,
					"Assembly":5,
					"QC":1.25,
					"Shipping":5
				}
			},
			{
				"id":"WO33668",
				"custName":"BTB Construction",
				"desc":"Bespoke metalwork parts",
				"numUnits":17,
				"totalParts":17,
				"creationOffset":-1,
				"dueOffset":14,
				"route":"Short Route",
				"cost":12000,
				"priority":1,
				"times":{
					"Cutting":3,
					"Welding":6,
					"Painting":0,
					"Assembly":0,
					"QC":3,
					"Shipping":3
				}
			},
			{
				"id":"WO33669",
				"custName":"Freeman Shipping",
				"desc":"Mount",
				"numUnits":1,
				"totalParts":27,
				"creationOffset":0,
				"dueOffset":21,
				"route":"Main Production Route",
				"cost":6000,
				"priority":1,
				"times":{
					"Cutting":1,
					"Welding":1,
					"Painting":1.5,
					"Assembly":2,
					"QC":0.5,
					"Shipping":0.5
				}
			}
		]

extraStationNames = ["Cutting","Welding","Painting","Assembly","QC","Shipping"]
productNames = ["Frame Assembly","Case Assembly"]
stoppageReasons = ["Breakdown","Material unavailable","Lack of fuel"]
productionRoutes = [
		{"name":"Main Production Route","description": "Cutting,Welding,Painting,Assembly,QC,Shipping"},
		{"name":"No Paint","description":"Cutting,Welding,Assembly,QC,Shipping"},
		{"name":"Short Route","description":"Cutting,Welding,QC,Shipping"}
	]
	
workStartTime = "08:00"
workEndTime = "17:00"
lunchStartTime = "12:00"
lunchEndTime = "13:00"

usersAtStations = {"Cutting":"user_0001", "Welding":"user_0002", "Painting":"user_0003", "Assembly":"user_0004", "QC":"user_0005", "Shipping":"user_0006"}

random.seed(1) #random numbers make generation easier. Setting the seed means we get the same result each time

conn = pymysql.connect(host=hostname, port=dbPort, user="server", password="gnlPdNTW1HhDuQGc", database="work_tracking", autocommit=True)
cursor = conn.cursor()

# convert job times to seconds. This is more easily done here than in the above list
for job in jobs:
	for stationName in extraStationNames:
		job["times"][stationName] *= 3600

# get any existing job IDs, user IDs, product IDs, and stoppage IDs, so that they can be fully removed from the system before the demo data is entered. This ensures that any QR codes that were generated will also be removed.

# delete all users except for the permanent system users
rowcount = cursor.execute("SELECT userId FROM users WHERE userIdIndex > 0")
for i in range(rowcount):
	userId = cursor.fetchone()[0]
	params = {"request":"deleteUser","userId":userId}
	print("Delete user {}".format(userId))
	requests.get("http://{}:{}/timelogger/scripts/server/users.php".format(hostname,serverPort),params=params)
	
	
rowcount = cursor.execute("SELECT jobId from jobs")
for i in range(rowcount):
	jobId = cursor.fetchone()[0]
	params = {"request":"deleteJob","jobId":jobId}
	print("Delete job {}".format(jobId))
	requests.get("http://{}:{}/timelogger/scripts/server/job_details.php".format(hostname,serverPort),params=params)
	
	
rowcount = cursor.execute("SELECT stoppageReasonId from stoppageReasons")
for i in range(rowcount):
	reasonId = cursor.fetchone()[0]
	params = {"request":"deleteStoppageReason","stoppageReasonId":reasonId}
	print("Delete stoppage reason {}".format(reasonId))
	requests.get("http://{}:{}/timelogger/scripts/server/stoppages.php".format(hostname,serverPort),params=params)
	
	
rowcount = cursor.execute("SELECT productId from products")
for i in range(rowcount):
	productId = cursor.fetchone()[0]
	params = {"request":"deleteProduct","productId":productId}
	print("Delete product {}".format(productId))
	requests.get("http://{}:{}/timelogger/scripts/server/products.php".format(hostname,serverPort),params=params)


# remove any existing routes and station data
print("Delete routes")
cursor.execute("DELETE FROM routes")
print("Delete extra scanner names")
cursor.execute("DELETE FROM extraScannerNames")
print("Delete connected clients")
cursor.execute("DELETE FROM connectedClients")


# Now that the system is empty, begin setting up the demo data.
# Set up users, stoppages, jobs, and products, allowing default values. This is 
# most easily done by making web requests to the server to get the relevant 
# QR codes to be generated, and then editing the databse directly.

for user in userNames:
	params = {"request":"addUser","userName":user}
	print("Create user {}".format(user))
	requests.get("http://{}:{}/timelogger/scripts/server/users.php".format(hostname,serverPort),params=params)
	
for reason in stoppageReasons:
	params = {"request":"addStoppageReason","stoppageReason":reason}
	print("Create stoppage reason {}".format(reason))
	requests.get("http://{}:{}/timelogger/scripts/server/stoppages.php".format(hostname,serverPort),params=params)
	
for productName in productNames:
	params = {"request":"addProduct","productId":productName}
	print("Create product {}".format(productName))
	requests.get("http://{}:{}/timelogger/scripts/server/products.php".format(hostname,serverPort),params=params)

for job in jobs:
	params = {"request":"addJob","jobId":job['id']}
	print("Create job {}".format(job['id']))
	requests.get("http://{}:{}/timelogger/scripts/server/add_job.php".format(hostname,serverPort),params=params)
	expectedDuration = job["times"]["Cutting"] + job["times"]["Welding"] + job["times"]["Painting"] + job["times"]["Assembly"] + job["times"]["QC"] + job["times"]["Shipping"]
	updateQuery = "UPDATE jobs SET customerName='{}',	description='{}',	numberOfUnits={}, totalParts={}, recordAdded = CURRENT_TIMESTAMP + INTERVAL {} DAY,\
					dueDate=CURRENT_DATE + INTERVAL {} DAY, expectedDuration={}, routeName='{}', totalChargeToCustomer={}, priority={}\
					WHERE jobId='{}'".format(
						job['custName'],job['desc'],job['numUnits'],job['totalParts'],job['creationOffset'],job['dueOffset'],
						expectedDuration,job['route'],job['cost'],job['priority'],job['id']
					)
					
	cursor.execute(updateQuery)
	
					
for route in productionRoutes:
	print("Add route {} ({})".format(route['name'], route['description']))
	cursor.execute("INSERT INTO routes (routeName, routeDescription) VALUES ('{}', '{}')".format(route['name'], route['description']))
	
for stationName in extraStationNames:
	print("Add extra scanner name {}".format(stationName))
	cursor.execute("INSERT INTO extraScannerNames (name) VALUES ('{}')".format(stationName))


# set work and lunch times
print("Set work and lunch times")
cursor.execute("UPDATE workHours SET startTime='{}', endTime='{}' WHERE DAYNAME(dayDate) != 'Saturday' AND DAYNAME(dayDate) != 'Sunday'".format(workStartTime, workEndTime))
cursor.execute("UPDATE lunchTimes SET startTime='{}', endTime='{}' WHERE DAYNAME(dayDate) != 'Saturday' AND DAYNAME(dayDate) != 'Sunday'".format(lunchStartTime, lunchEndTime))

# Now for the fun part. The time log is generated by having effectively simulating, in a simple manner,
# users actually working on jobs and using the system.
workDateInitialOffset = -14
timeJiggleSec = 180 # time variation +- from ideal clocking times
minTimeToStartJob = 300 # won't start a job in the morning/afternoon if less than this is avaiable

print("Begin timelog generation")

# queues of jobs and times are used to record when jobs become available to each station
queues = {"Cutting":[],"Welding":[],"Painting":[],"Assembly":[],"QC":[],"Shipping":[]}


cursor.execute("SELECT startTime FROM workHours WHERE DAYNAME(dayDate) = DAYNAME(CURRENT_DATE + INTERVAL {} DAY) LIMIT 1".format(workDateInitialOffset))
dayStartSec = cursor.fetchone()[0].seconds;

for job in jobs:
	queues["Cutting"].append({"job":job, "canStartSecs":dayStartSec, "canStartOffset":job["creationOffset"]})


stationNameCount = len(extraStationNames)
for i in range(stationNameCount):
	stationName = extraStationNames[i]
	
	print("Generating log for {}".format(stationName))
	
	currentWorkDateOffset = workDateInitialOffset
	
	while(currentWorkDateOffset < 0):
		#print("Working on day offset {}".format(currentWorkDateOffset))
		cursor.execute("SELECT startTime FROM workHours WHERE DAYNAME(dayDate) = DAYNAME(CURRENT_DATE + INTERVAL {} DAY) LIMIT 1".format(currentWorkDateOffset))
		dayStartSec = cursor.fetchone()[0].seconds;

		cursor.execute("SELECT endTime FROM workHours WHERE DAYNAME(dayDate) = DAYNAME(CURRENT_DATE + INTERVAL {} DAY) LIMIT 1".format(currentWorkDateOffset))
		dayEndSec = cursor.fetchone()[0].seconds;

		cursor.execute("SELECT startTime FROM lunchTimes WHERE DAYNAME(dayDate) = DAYNAME(CURRENT_DATE + INTERVAL {} DAY) LIMIT 1".format(currentWorkDateOffset))
		lunchStartSec = cursor.fetchone()[0].seconds;

		cursor.execute("SELECT endTime FROM lunchTimes WHERE DAYNAME(dayDate) = DAYNAME(CURRENT_DATE + INTERVAL {} DAY) LIMIT 1".format(currentWorkDateOffset))
		lunchEndSec = cursor.fetchone()[0].seconds;

		morningAvailableSec = lunchStartSec - dayStartSec
		afternoonAvailableSec = dayEndSec - lunchEndSec

		if morningAvailableSec == 0 or afternoonAvailableSec == 0:
			currentWorkDateOffset += 1
			continue # we don't work weekends


		times = [{"startTime":dayStartSec,"availableDuration":morningAvailableSec},{"startTime":lunchEndSec,"availableDuration":afternoonAvailableSec}]
		for timeSet in times:
			currentTime = timeSet["startTime"]
			while timeSet['availableDuration'] > minTimeToStartJob:
				# if a job is available today or earlier, and there's time to start before lunch/end of day, work on that job
				if len(queues[stationName]) > 0 and (
						(queues[stationName][0]["canStartSecs"] <= currentTime and queues[stationName][0]["canStartOffset"] == currentWorkDateOffset) or
						queues[stationName][0]["canStartOffset"] < currentWorkDateOffset):
					job = queues[stationName][0]["job"]

					# determine the index of the current station on the production route
					for route in productionRoutes:
						if route["name"] == job["route"]:
							routeParts = route["description"].split(",")
							break

					if stationName in routeParts:
						for routeIndex in range(len(routeParts)):
							if (stationName == routeParts[routeIndex]):
								break

						routeIndex += 1 # the first station in a route is recorded as 1

						startJiggle = random.randint(0, timeJiggleSec)
						timeSet['availableDuration'] -= startJiggle
						currentTime = currentTime + startJiggle

						workJiggle = random.randint(0, timeJiggleSec)

						timeToWork = int(min(timeSet['availableDuration'],job["times"][stationName]) + workJiggle)

						startTime = currentTime
						currentTime += int(timeToWork)
						timeSet['availableDuration'] -= timeToWork


						currentTimeStr = secondsToTimeStr(currentTime)
						startTimeStr = secondsToTimeStr(startTime)

						cursor.execute("SELECT CURRENT_DATE + INTERVAL {} DAY".format(currentWorkDateOffset))
						d = cursor.fetchone()[0]
						dateStr = "{:04}-{:02}-{:02}".format(d.year,d.month,d.day)
						timestampStr = dateStr + " " + startTimeStr

						# print("Working on {} at {} for {} seconds".format(job['id'], stationName, timeToWork))

						# have the database calculate the overtime for us
						cursor.execute("SELECT CalcOvertimeDuration('{}','{}','{}')".format(startTimeStr, currentTimeStr, dateStr))
						overtime = cursor.fetchone()[0]

						cursor.execute(
							"INSERT INTO timeLog(jobId, stationId, userId, clockOnTime, clockOffTime, recordDate, recordTimestamp, workedDuration, overtimeDuration, workStatus, routeStageIndex) " +
							"VALUES ('{}','{}','{}','{}','{}','{}','{}',{},{},'{}',{})".format(
								job['id'], stationName, usersAtStations[stationName], startTimeStr, currentTimeStr, dateStr, timestampStr, timeToWork, overtime, "workInProgress",routeIndex)
							)

						job["times"][stationName] -= timeToWork
						cursor.execute("UPDATE jobs SET currentStatus='workInProgress' WHERE jobId='{}'".format(job["id"]))
						cursor.execute("UPDATE jobs SET routeCurrentStageName='{}', routeCurrentStageIndex={} WHERE jobId='{}'".format(stationName, routeIndex, job['id']))

					# if the job is done, mark it as so in the database and put it on the queue for the next station
					if job["times"][stationName] <= 0:
						if stationName in routeParts: #only update if the job actually visits this station
							cursor.execute("SELECT MAX(ref) FROM timeLog LIMIT 1")
							ref = cursor.fetchone()[0]
							cursor.execute("UPDATE timeLog SET workStatus = 'stageComplete' WHERE ref = {}".format(ref))

						# add to the next queue if this isn't the last station, otherwise mark job as complete
						if stationName != extraStationNames[-1]:
							queues[extraStationNames[i + 1]].append({"job":job, "canStartSecs":currentTime, "canStartOffset":currentWorkDateOffset})

						else:
							cursor.execute("UPDATE jobs SET currentStatus='complete' WHERE jobId='{}'".format(job["id"]))

						queues[stationName].pop(0)


				# check if a job is available later today, and if it is, jump to that time
				elif len(queues[stationName]) > 0 and queues[stationName][0]["canStartOffset"] == currentWorkDateOffset and queues[stationName][0]["canStartSecs"] > currentTime and queues[stationName][0]["canStartSecs"] < (timeSet['availableDuration'] + currentTime):
					currentTime = queues[stationName][0]["canStartSecs"]
					timeSet['availableDuration'] -= (currentTime - timeSet["startTime"])


				# no jobs available for this time period
				else:
					break
					
				
		# end of the day. Add 1 to the offset and begin tomorrow for this station		
		currentWorkDateOffset += 1
	
print("Timelog generated")
print("Updating jobs with worked times")	

#conn.commit()

for job in jobs:	
	cursor.execute("SELECT SUM(workedDuration), SUM(overtimeDuration) FROM timeLog WHERE jobId='{}'".format(job['id']))
	row = cursor.fetchone()
	workedTime, overtime = row[0], row[1]
	if workedTime == None:
		workedTime = 0
	if overtime == None:
		overtime = 0
	
	cursor.execute("UPDATE jobs SET closedWorkedDuration={}, closedOvertimeDuration={} WHERE jobId='{}'".format(workedTime, overtime, job['id']))
	
print("Done")

conn.commit()



