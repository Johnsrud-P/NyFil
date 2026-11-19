# NyFil

NyFil er en liten macOS-app som legger til et **NyFil**-valg i høyreklikkmenyen i Finder.

- **Ny fil**: opprett en tom Excel-arbeidsbok (.xlsx), et Word-dokument (.docx), en PowerPoint-presentasjon (.pptx) eller en tekstfil (.txt) i mappen du står i. Excel-filen kan du gi navn med en gang.
- **Flytt til**: flytt markerte filer og mapper til en av de sist brukte mappene eller til en mappe du velger. Eksisterende filer blir aldri overskrevet. Ved navnekollisjon får filen et nummer.
- **Kopier sti**: kopier den fulle stien til filer, mapper eller mappen du står i.

Appen og menyene er på norsk bokmål. Den krever macOS 13 eller nyere.

## Last ned og installer

1. Last ned `NyFil-<versjon>.zip` fra [siste utgivelse](https://github.com/Johnsrud-P/NyFil/releases/latest) og pakk den ut.
2. Flytt `Nyfil.app` til **Programmer**.
3. Åpne appen. Fordi appen ikke er notarisert av Apple, stopper macOS den første gang:
   - Trykk **Ferdig** i advarselen.
   - Gå til **Systeminnstillinger → Personvern og sikkerhet**, bla ned og trykk **Åpne likevel** ved NyFil.
   - Åpne appen igjen og bekreft.
4. Trykk **Åpne innstillinger for Finder-utvidelser** i appen og slå på NyFil.
5. Høyreklikk i en mappe i Finder og velg **NyFil**.

Appen virker på både Apple Silicon og Intel.

Alternativt kan du fjerne advarselen fra Terminal før du åpner appen:

```sh
xattr -dr com.apple.quarantine /Applications/Nyfil.app
```

## Bygg selv

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

## Lisens

MIT. Se [LICENSE](LICENSE).
