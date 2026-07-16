# APTGRAM - Codex-Anweisungen

## Lokale Debian-Test-VM

Wenn der Benutzer sinngemaess eine der folgenden Anweisungen gibt:

- "Schiebe das Paket auf unsere VM."
- "Uebertrage APTGRAM auf die Test-VM."
- "Deploye den aktuellen Stand auf die VM."

Fuehre ausschliesslich den Befehl `./tools/deploy-vm` im Projektstamm aus.

Das Skript uebertraegt den aktuellen Projektstand in das konfigurierte
Installationsverzeichnis der lokalen Test-VM.

Dabei gelten folgende Regeln:

- Keine eigenen SSH-, SCP-, TAR- oder PowerShell-Befehle erstellen.
- SSH-Konfiguration und private Schluessel nicht untersuchen oder veraendern.
- Keine Installation auf der VM durchfuehren.
- Kein sudo verwenden, ausser der Benutzer verlangt es ausdruecklich.
- Nach der Ausfuehrung das Ergebnis und moegliche Fehlermeldungen vollstaendig wiedergeben.

## Git-Ausgaben

Bei Git-Befehlen standardmaessig `--no-pager` verwenden, wenn sonst ein Pager geoeffnet werden koennte.

## Vor jedem Commit

Codex muss vor jedem Commit:

1. Git-Status und den vollstaendigen Diff pruefen.
2. Die fuer den Aenderungsumfang relevanten automatischen Tests ausfuehren.
3. Pruefen, ob README oder Benutzerdokumentation angepasst werden muessen.
4. Pruefen, ob ein Versionssprung sinnvoll ist.
5. Eine oder mehrere logisch getrennte Commit-Nachrichten vorschlagen.
6. Die geplante Dateizuordnung fuer jeden Commit anzeigen.
7. Vor dem Staging und Commit die ausdrueckliche Bestaetigung des Benutzers einholen.

## Vor jedem Release

Codex muss vor jedem Release zusaetzlich:

1. Einen semantischen Versionssprung empfehlen und bestaetigen lassen.
2. `VERSION`, Git-Tag und Changelog auf Uebereinstimmung pruefen.
3. `CHANGELOG.md`, README und alle betroffenen Benutzerdokumentationen pruefen.
4. Das Allowlist-Release-Paket bauen und den vollstaendigen Inhalt pruefen.
5. Die SHA-256-Pruefsumme erzeugen und verifizieren.
6. Alle automatischen Release-Pruefungen ausfuehren und Ergebnisse anzeigen.
7. Risiken, offene Punkte, Commit-Plan, Tag und GitHub-Release-Plan anzeigen.
8. Vor Staging und Commits eine ausdrueckliche Freigabe einholen.
9. Nach den Commits eine weitere ausdrueckliche Freigabe fuer Push und Tag einholen.

## Verbotene Git- und Release-Aktionen ohne Freigabe

Ohne vorherige ausdrueckliche Bestaetigung darf Codex niemals:

- Dateien stagen,
- einen Commit erstellen,
- einen Branch pushen,
- einen Git-Tag erstellen oder veraendern,
- einen Tag pushen,
- einen GitHub Release erstellen,
- bestehende Releases oder Tags ueberschreiben oder loeschen,
- einen Force-Push ausfuehren.

Bereits vergebene Versionsnummern und veroeffentlichte Tags duerfen nicht erneut verwendet werden.

## Release-Ablauf

- Die zentrale Versionsquelle ist `VERSION` im Projektstamm.
- Release-Tags verwenden das Format `vX.Y.Z` und sind annotiert.
- Offizielle Endnutzerpakete werden ausschliesslich mit `tools/build-release.sh` erzeugt.
- Vor einem Release ist `tools/check-release.sh --tag vX.Y.Z` auszufuehren.
- GitHub Releases werden durch `.github/workflows/release.yml` erst nach dem Push eines bestaetigten Tags erstellt.
- Bei einem fehlgeschlagenen Workflow darf keine Ersatzversion und kein Ersatz-Tag automatisch erzeugt werden. Zuerst ist die Ursache zu analysieren und dem Benutzer vorzulegen.
