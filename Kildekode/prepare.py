from pathlib import Path
import plistlib
import sys

from docx import Document
from openpyxl import Workbook
from pptx import Presentation
from pptx.util import Inches


app = Path(sys.argv[1]) / "Contents"
extension = app / "PlugIns/NyfilFinder.appex/Contents"
resources = extension / "Resources"

for directory in (app / "MacOS", app / "Resources", extension / "MacOS", resources):
    directory.mkdir(parents=True, exist_ok=True)

base = {
    "CFBundleDevelopmentRegion": "nb",
    "CFBundleShortVersionString": "1.2",
    "CFBundleVersion": "3",
    "CFBundleName": "NyFil",
    "CFBundleDisplayName": "NyFil",
    "LSMinimumSystemVersion": "13.0",
}

with (app / "Info.plist").open("wb") as plist:
    plistlib.dump(base | {
        "CFBundleIdentifier": "no.nyfil.mac",
        "CFBundleExecutable": "Nyfil",
        "CFBundlePackageType": "APPL",
        "CFBundleIconFile": "Nyfil",
        "LSApplicationCategoryType": "public.app-category.utilities",
        "NSDocumentsFolderUsageDescription": "NyFil oppretter og flytter filer i Dokumenter når du bruker NyFil i Finder.",
        "NSDownloadsFolderUsageDescription": "NyFil oppretter og flytter filer i Nedlastinger når du bruker NyFil i Finder.",
        "NSDesktopFolderUsageDescription": "NyFil oppretter og flytter filer på Skrivebord når du bruker NyFil i Finder.",
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
presentation = Presentation()
presentation.slide_width = Inches(13.333)
presentation.slide_height = Inches(7.5)
for field in ("author", "last_modified_by", "comments", "title"):
    setattr(presentation.core_properties, field, "")
presentation.save(resources / "Tom.pptx")
