'''
Copyright 2022 DigitME2

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

from socket import socket, AF_INET, SOCK_DGRAM
from time import sleep

# note, this file is mostly borrowed from the OEE server & Copied from Inverntory Server

""" Listens for a device broadcast and responds, so the device can discover this server. """

BROADCAST_PORT = 8093  # This should match the port set in the app
EXPECTED_TEXT = "DISCOVER_PTT_SERVER_REQUEST"
EXPECTED_RESPONSE = "DISCOVER_PTT_SERVER_RESPONSE"
SERVER_PORT = "80"
PROTOCOL = "http"

s = socket(AF_INET, SOCK_DGRAM)
s.bind(('', BROADCAST_PORT))

print("Listening for device broadcasts")
while 1:
    data, addr = s.recvfrom(1024)  # Wait for a packet
    print("Received broadcast:", data.decode("utf-8"))

    if data.decode("utf-8") == EXPECTED_TEXT:
        print("Responding...")
        s.sendto((EXPECTED_RESPONSE + ":" + PROTOCOL + ":" + SERVER_PORT).encode("utf-8"), addr)

    sleep(5)
