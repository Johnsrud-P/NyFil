# NyFil

NyFil er en liten macOS-app som legger til et **NyFil**-valg i høyreklikkmenyen i Finder.

- **Ny fil**: opprett en tom Excel-arbeidsbok (.xlsx), et Word-dokument (.docx), en PowerPoint-presentasjon (.pptx) eller en tekstfil (.txt) i mappen du står i. Excel-filen kan du gi navn med en gang.
- **Flytt til**: flytt markerte filer og mapper til en av de sist brukte mappene eller til en mappe du velger. Eksisterende filer blir aldri overskrevet. Ved navnekollisjon får filen et nummer.
- **Kopier sti**: kopier den fulle stien til filer, mapper eller mappen du står i.

Appen og menyene er på norsk bokmål. Den krever macOS 13 eller nyere.

## Bygg

Du trenger Xcode Command Line Tools og Python 3.

```sh
python3 -m venv .venv
.venv/bin/pip install python-docx openpyxl python-pptx
mkdir -p Bygg
bash Kildekode/build.sh "Bygg/test/Nyfil.app" "$PWD/.venv/bin/python"
```

Flytt `Nyfil.app` til Programmer og åpne den. Slå på utvidelsen under Systeminnstillinger → Generelt → Påloggingsobjekter og utvidelser → Finder.

Appen signeres lokalt (ad hoc) og er ikke notarisert av Apple.

## Tester

Testskriptene i `Testfiler/` sjekker filopprettelse, navnebytte og flytting. Se `NyFil.md` for detaljer om prosjektet.
