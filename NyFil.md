# NyFil

NyFil er en lokal macOS-app med en Finder Sync-utvidelse. Høyreklikk i Finder og velg **NyFil**. Alle valg ligger samlet der. I en mappe kan du opprette en tom Excel-arbeidsbok (.xlsx), et Word-dokument (.docx), en PowerPoint-presentasjon (.pptx) eller en tekstfil (.txt). Nederst i samme meny ligger **Flytt til** (for markerte filer og mapper) og **Kopier sti**. Appen og Finder-menyen bruker norsk bokmål. Visningsnavnet er «NyFil», men filnavn, kjørbare filer og ID-er heter fortsatt `Nyfil`.

## Prosjektfiler

- `Kildekode/FinderExtension.swift` bygger Finder-menyen, viser navnedialogen for Excel og mappevelgeren for «Flytt til».
- `Kildekode/FileMove.swift` flytter filer og husker de fem sist brukte målmappene. Flytting skal aldri overskrive. Ved navnekollisjon får objektet et nummer.
- `Kildekode/FileCreation.swift` oppretter og gir nytt navn til filer. Ved opprettelse får duplikater et nummer. Navnebytte skal bevare filinnholdet og aldri overskrive en eksisterende fil.
- `Kildekode/Nyfil.swift` viser status og åpner innstillingene for Finder-utvidelser.
- `Kildekode/build.sh` bygger appen og utvidelsen. `prepare.py` lager pakkemetadata og Office-maler. `Icon.swift` og `package_icon.py` lager appikonet.
- `Bygg/` inneholder én mappe per versjon (`1.0`, `1.1`, `1.2`) for tilbakeføring. Når et testbygg er godkjent og installert, gi det versjonsnavnet og fjern eldre testbygg. `Testfiler/` inneholder testskriptene `Check.swift`, `RenameCheck.swift` og `MoveCheck.swift`, pluss lokale testresultater som ikke ligger i git.

## Nåværende oppførsel

Kildekoden er versjon 1.2. Versjon 1.1 er installert i `/Applications/Nyfil.app`. Brukeren har bekreftet at Excel-dialogen fungerer i Finder. Dialogen åpnes etter opprettelse og markerer navnet. Enter bekrefter navnet. Esc beholder standardnavnet. Word- og tekstfiler opprettes direkte. App-ID-en er `no.nyfil.mac` og utvidelsens ID er `no.nyfil.mac.finder`.

## Bygg og verifisering

Bygget trenger Xcode Command Line Tools og Python med pakkene `python-docx`, `openpyxl` og `python-pptx`. Prosjektet har et eget miljø i `.venv/` (`python3 -m venv .venv && .venv/bin/pip install python-docx openpyxl python-pptx`). Skriptet bygger for Macens arkitektur med macOS 13 som minsteversjon. Det signerer utvidelsen og appen lokalt og kontrollerer signaturene.

Fra prosjektroten, bruk en Python-tolk som har begge pakkene. Sett `NYFIL_PYTHON` til full sti hvis `python3` ikke har dem. Bygg i en ny mappe slik at eksisterende bygg kan brukes til sammenligning og tilbakeføring. `build.sh` bruker ett felles kompilatormellomlager i `.cache/ModuleCache` (rundt 280 MB) som gjenbrukes av alle bygg. Ikke lag egne mellomlagre per bygg.

```sh
mkdir -p Bygg
nyfil_build_dir="$(mktemp -d "$PWD/Bygg/test.XXXXXX")"
bash Kildekode/build.sh "$nyfil_build_dir/Nyfil.app" "${NYFIL_PYTHON:-$PWD/.venv/bin/python}"
codesign --verify --deep --strict "$nyfil_build_dir/Nyfil.app"
```

Når Finder-menyen eller filopprettelsen endres, sjekk i Finder at alle fire filtypene opprettes, at navnebytte og avbrudd fungerer for Excel, og at «Flytt til» og «Kopier sti» fungerer. Finder-utvidelsen kan lastes på nytt ved å slå den av og på i Systeminnstillinger.
