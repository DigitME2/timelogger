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

conn = pymysql.connect(host=hostname, port=dbPort, user="server", password="gnlPdNTW1HhDuQGc", database="work_tracking", autocommit=True)
cursor = conn.cursor()

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

