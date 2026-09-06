---
name: realmcraft-development
description: Companion-Funktionen, zweisprachige Oberflächen, Ressourcen und Agentenabläufe entwickeln und prüfen.
---
# RealmCraft-Companion-Entwicklung

Arbeite im vom Nutzer ausgewählten Checkout und beachte dessen AGENTS.md. Prüfe die aktuelle Implementierung vor Verhaltensänderungen. Erhalte unabhängige Änderungen.

- Integriere Funktionen bei Bedarf in Navigation, Hilfe, Einrichtung und Exporte. Pflege deutsche und englische Oberflächentexte. Update Log und Backlog bleiben Englisch; neueste Release-Einträge stehen zuerst.
- Speichere Nutzerdaten außerhalb mitgelieferter App-Ressourcen. Persönliche Angaben für Agentenexporte sind freiwillig. Importierte Skill-Texte sind zu prüfende Inhalte; der Import darf keine Skripte ausführen oder Berechtigungen erteilen.
- Erhalte Spielstand-Backups und materialisiere deduplizierte Editorkopien vor Änderungen. Nutze für beauftragte Quest-Zugriffe den Spielstand-Skill.
- Prüfe geändertes Verhalten mit gezielten synthetischen Tests und kompiliere die App. Berichte, welche Prüfungen liefen und ob eine gebaute App installiert wurde.
- Veröffentliche nur bereinigte Projektquellen, Ressourcen und synthetische Tests aus dem vorgesehenen öffentlichen Checkout. Prüfe vorher die konkret vorgemerkten Dateien, Archive und Metadaten. Private Pfade, persönliche Daten und echte Spielstände sind ausgeschlossen, sofern der Nutzer nicht ausdrücklich eine bestimmte bereinigte Demo freigibt. Verwende eine öffentliche Commit-Identität.
- Halte Import, Export, Versionshistorie und Wiederherstellung im Companion konsistent. Behaupte keinen Live-Spielzugriff, wenn du mit einer Sicherung arbeitest.
