#  Copyright 2022 DigitME2

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import qrcode
import sys

if len(sys.argv) < 3:
    print("Usage: {} <data to encode> <path to save to>".format(sys.argv[0]))
    sys.exit(1)
    
print("generating code")
code = sys.argv[1]
path = sys.argv[2]

# note: uses the most robust error correction setting.
# Seems valuable for a factory.
qr = qrcode.QRCode(
    version=None,
    error_correction=qrcode.constants.ERROR_CORRECT_H,
    box_size=5,
    border=4
)

qr.add_data(code)
qr.make(fit=True)
img = qr.make_image()

img.save(path)
print(path)
