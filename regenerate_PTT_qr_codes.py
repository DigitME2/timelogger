# Regenerates all system QR codes after a new docker image is installed. Gets the details from the database
# For jobs: QR code encodes the job number
# For users: QR code encodes the user id (user_xxxx)
# For products: QR code encodes prdt_<productId>, for example prdt_Case_Assembly
# For stoppages: QR code encodes stoppage id (stpg_xxxx)

import pymysql
import qrcode
import requests
import random

hostname = "localhost"
dbPort = 3306
serverPort = 80

conn = pymysql.connect(host=hostname, port=dbPort, user="server", password="gnlPdNTW1HhDuQGc", database="work_tracking", autocommit=True)
cursor = conn.cursor()


# jobs first
rowCount = cursor.execute("SELECT jobId, absolutePathToQrCode FROM jobs")

for i in range(rowCount):
	row = cursor.fetchone()
	jobId = row[0]
	qrCodePath = row[1]
	print(f"Generating job QR code for {jobId} at {qrCodePath}")
	
	qr = qrcode.QRCode(
		version=None,
		error_correction = qrcode.constants.ERROR_CORRECT_H,
		box_size = 5,
		border = 5
	)
	qr.add_data(jobId)
	qr.make(fit=True)
	
	img = qr.make_image()
	img.save(qrCodePath)
	
	
print("------------")

# then users
rowCount = cursor.execute("SELECT userId, absolutePathToQrCode FROM users WHERE absolutePathToQrCode IS NOT NULL")

for i in range(rowCount):
	row = cursor.fetchone()
	userId = row[0]
	qrCodePath = row[1]
	print(f"Generating QR code for {userId} at {qrCodePath}")
	
	qr = qrcode.QRCode(
		version=None,
		error_correction = qrcode.constants.ERROR_CORRECT_H,
		box_size = 5,
		border = 5
	)
	qr.add_data(userId)
	qr.make(fit=True)
	
	img = qr.make_image()
	img.save(qrCodePath)
	
	
print("------------")
		



# then stoppages
rowCount = cursor.execute("SELECT stoppageReasonId, absolutePathToQrCode FROM stoppageReasons")

for i in range(rowCount):
	row = cursor.fetchone()
	stoppageId = row[0]
	qrCodePath = row[1]
	print(f"Generating QR code for {stoppageId} at {qrCodePath}")
	
	qr = qrcode.QRCode(
		version=None,
		error_correction = qrcode.constants.ERROR_CORRECT_H,
		box_size = 5,
		border = 5
	)
	qr.add_data(stoppageId)
	qr.make(fit=True)
	
	img = qr.make_image()
	img.save(qrCodePath)
	
	
print("------------")
		



# and finally products
rowCount = cursor.execute("SELECT productId, absolutePathToQrCode FROM products")

for i in range(rowCount):
	row = cursor.fetchone()
	productId = row[0]
	qrCodePath = row[1]
	print(f"Generating QR code for {productId} at {qrCodePath}")
	
	qr = qrcode.QRCode(
		version=None,
		error_correction = qrcode.constants.ERROR_CORRECT_H,
		box_size = 5,
		border = 5
	)
	qr.add_data("pdrt_" + productId)
	qr.make(fit=True)
	
	img = qr.make_image()
	img.save(qrCodePath)
	
	
print("------------")
print("done")
	
	
