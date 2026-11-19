from pathlib import Path
import struct
import sys

source, destination = (Path(argument) for argument in sys.argv[1:])
icon_types = {
    b"icp4": "icon_16x16",
    b"icp5": "icon_32x32",
    b"ic07": "icon_128x128",
    b"ic08": "icon_256x256",
    b"ic09": "icon_512x512",
    b"ic10": "icon_512x512@2x",
    b"ic11": "icon_16x16@2x",
    b"ic12": "icon_32x32@2x",
    b"ic13": "icon_128x128@2x",
    b"ic14": "icon_256x256@2x",
}
images = bytearray()
for icon_type, name in icon_types.items():
    png = (source / f"{name}.png").read_bytes()
    images.extend(struct.pack(">4sI", icon_type, len(png) + 8))
    images.extend(png)
destination.write_bytes(struct.pack(">4sI", b"icns", len(images) + 8) + images)
