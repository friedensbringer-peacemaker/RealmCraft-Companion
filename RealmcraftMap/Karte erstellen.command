#!/bin/zsh
cd -- "${0:A:h}"
if ! command -v python3 >/dev/null || ! python3 -c 'import numpy; import PIL' 2>/dev/null; then
  print 'Zum Erstellen werden Python 3, NumPy und Pillow benötigt.'
  print 'Einmalig: python3 -m pip install -r requirements.txt'
  read '?Enter zum Schließen … '
  exit 1
fi
SAVEGAME_FOLDER=$(osascript -e 'POSIX path of (choose folder with prompt "Realmcraft-Weltordner wählen (enthält o.x,z und n.x,z):")') || exit 0
python3 -m realmcraft_map "$SAVEGAME_FOLDER" --output output --open
RESULT=$?
if (( RESULT != 0 )); then
  print 'Bitte die Meldung oben beachten. Exitcode 2 bedeutet: Teilkarte oder einzelne Dateien fehlen.'
fi
read '?Enter zum Schließen … '
exit "$RESULT"
