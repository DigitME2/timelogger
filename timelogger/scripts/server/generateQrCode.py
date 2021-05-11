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
