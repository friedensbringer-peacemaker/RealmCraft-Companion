#!/bin/zsh
cd -- "${0:A:h}"
if [[ -f output/index.html ]]; then
  open output/index.html
elif [[ -f preview/index.html ]]; then
  open preview/index.html
else
  print 'Bitte zuerst „Karte erstellen.command“ starten.'
  read '?Enter zum Schließen … '
fi
