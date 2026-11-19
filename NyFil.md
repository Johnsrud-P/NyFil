# Nyfil

Nyfil er en lokal macOS-app med en Finder Sync-utvidelse. Høyreklikk i en mappe i Finder og velg **Ny fil** for å opprette en tom Excel-arbeidsbok (.xlsx), et Word-dokument (.docx) eller en tekstfil (.txt). Appen og Finder-menyen bruker norsk bokmål.

## Prosjektfiler

- `Kildekode/FinderExtension.swift` bygger Finder-menyen og viser navnedialogen for Excel.
- `Kildekode/FileCreation.swift` oppretter og gir nytt navn til filer. Ved opprettelse får duplikater et nummer. Navnebytte skal bevare filinnholdet og aldri overskrive en eksisterende fil.
- `Kildekode/Nyfil.swift` viser status og åpner innstillingene for Finder-utvidelser.
- `Kildekode/build.sh` bygger appen og utvidelsen. `prepare.py` lager pakkemetadata og Office-maler. `Icon.swift` og `package_icon.py` lager appikonet.
- `Bygg/` inneholder tidligere bygg og en kopi for tilbakeføring. `Testfiler/` inneholder lokale testskript og testresultater. `Utgivelser/` inneholder ZIP-pakken for versjon 1.1.

## Nåværende oppførsel

Versjon 1.1 er installert i `/Applications/Nyfil.app`. Brukeren har bekreftet at Excel-dialogen fungerer i Finder. Dialogen åpnes etter opprettelse og markerer navnet. Enter bekrefter navnet. Esc beholder standardnavnet. Word- og tekstfiler opprettes direkte. App-ID-en er `no.nyfil.mac` og utvidelsens ID er `no.nyfil.mac.finder`.

## Bygg og verifisering

Bygget trenger Xcode Command Line Tools og Python med pakkene `python-docx` og `openpyxl`. Skriptet bygger for Macens arkitektur med macOS 13 som minsteversjon. Det signerer utvidelsen og appen lokalt og kontrollerer signaturene.

Fra prosjektroten, bruk en Python-tolk som har begge pakkene. Sett `NYFIL_PYTHON` til full sti hvis `python3` ikke har dem. Bygg i en ny mappe slik at eksisterende bygg kan brukes til sammenligning og tilbakeføring.

```sh
mkdir -p Bygg
nyfil_build_dir="$(mktemp -d "$PWD/Bygg/test.XXXXXX")"
mkdir -p "$nyfil_build_dir/ModuleCache"
export CLANG_MODULE_CACHE_PATH="$nyfil_build_dir/ModuleCache"
bash Kildekode/build.sh "$nyfil_build_dir/Nyfil.app" "${NYFIL_PYTHON:-python3}"
codesign --verify --deep --strict "$nyfil_build_dir/Nyfil.app"
```

Når Finder-menyen eller filopprettelsen endres, sjekk i Finder at alle tre filtypene opprettes og at navnebytte og avbrudd fungerer for Excel. Finder-utvidelsen kan lastes på nytt ved å slå den av og på i Systeminnstillinger.
