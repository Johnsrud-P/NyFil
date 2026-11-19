from pathlib import Path
import plistlib
import sys

from docx import Document
from openpyxl import Workbook


app = Path(sys.argv[1]) / "Contents"
extension = app / "PlugIns/NyfilFinder.appex/Contents"
resources = extension / "Resources"

for directory in (app / "MacOS", app / "Resources", extension / "MacOS", resources):
    directory.mkdir(parents=True, exist_ok=True)

base = {
    "CFBundleDevelopmentRegion": "nb",
    "CFBundleShortVersionString": "1.1",
    "CFBundleVersion": "2",
    "CFBundleName": "Nyfil",
    "CFBundleDisplayName": "Nyfil",
    "LSMinimumSystemVersion": "13.0",
}

with (app / "Info.plist").open("wb") as plist:
    plistlib.dump(base | {
        "CFBundleIdentifier": "no.nyfil.mac",
        "CFBundleExecutable": "Nyfil",
        "CFBundlePackageType": "APPL",
        "CFBundleIconFile": "Nyfil",
        "LSApplicationCategoryType": "public.app-category.utilities",
        "NSDocumentsFolderUsageDescription": "Nyfil oppretter filer i Dokumenter når du velger Ny fil i Finder.",
        "NSDownloadsFolderUsageDescription": "Nyfil oppretter filer i Nedlastinger når du velger Ny fil i Finder.",
        "NSDesktopFolderUsageDescription": "Nyfil oppretter filer på Skrivebord når du velger Ny fil i Finder.",
    }, plist)

with (extension / "Info.plist").open("wb") as plist:
    plistlib.dump(base | {
        "CFBundleIdentifier": "no.nyfil.mac.finder",
        "CFBundleExecutable": "NyfilFinder",
        "CFBundlePackageType": "XPC!",
        "NSExtension": {
            "NSExtensionPointIdentifier": "com.apple.FinderSync",
            "NSExtensionPrincipalClass": "NyfilFinderExtension",
        },
    }, plist)

with (Path(sys.argv[1]).parent / "NyfilFinder.entitlements").open("wb") as plist:
    plistlib.dump({
        "com.apple.security.app-sandbox": True,
        "com.apple.security.temporary-exception.files.absolute-path.read-write": ["/"],
    }, plist)

workbook = Workbook()
workbook.active.title = "Ark1"
workbook.save(resources / "Tom.xlsx")
document = Document()
document.core_properties.author = ""
document.core_properties.last_modified_by = ""
document.core_properties.comments = ""
document.core_properties.title = ""
document.save(resources / "Tom.docx")
