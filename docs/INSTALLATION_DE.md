# APTGRAM – Installation auf Deutsch

[← Zurück zur README](../README.md)

Diese Anleitung führt Schritt für Schritt durch die Einrichtung des Telegram-Bots, des Telegram-Kanals und die Installation von APTGRAM.

## Installation

APTGRAM ist für Debian-basierte Linux-Systeme mit `systemd` und APT-Paketverwaltung entwickelt.

Dazu gehören zum Beispiel:

- Debian
- Ubuntu
- Debian-basierte Server-Systeme
- kompatible UGREEN NAS-Systeme mit UGOS Pro

Für die Installation benötigst du außerdem:

- einen Telegram-Bot
- einen Telegram-Kanal für die APTGRAM-Benachrichtigungen
- den **Telegram Bot Token**
- die numerische **Telegram Chat ID** des Kanals

Du hast noch nie einen Telegram-Bot eingerichtet?

Kein Problem. Die folgenden Schritte führen dich vollständig durch die Einrichtung.

---

### 1. Telegram-Bot erstellen

Öffne Telegram und suche nach:

```text
@BotFather
```

Achte darauf, den offiziellen BotFather von Telegram zu verwenden.

Öffne den Chat und sende:

```text
/newbot
```

BotFather führt dich nun durch die Erstellung deines Bots.

#### Bot-Namen festlegen

Zuerst fragt BotFather nach einem Namen für den Bot.

Dieser Name wird später in Telegram angezeigt.

Beispiel:

```text
APTGRAM Server
```

Der Name kann frei gewählt werden.

#### Bot-Benutzernamen festlegen

Anschließend benötigt der Bot einen eindeutigen Benutzernamen.

Der Benutzername muss auf `bot` enden.

Beispiel:

```text
my_aptgram_bot
```

Ist der Benutzername bereits vergeben, musst du einen anderen Namen wählen.

Nach erfolgreicher Erstellung zeigt BotFather den **Telegram Bot Token** an.

Ein Bot Token sieht ungefähr so aus:

```text
1234567890:AAExampleTokenDoNotUseThisValue
```

Kopiere den vollständigen Token.

Du benötigst ihn später während der APTGRAM-Installation.

> [!IMPORTANT]
> Der Telegram Bot Token ist ein Geheimnis und muss wie ein Passwort behandelt werden.
>
> Veröffentliche den Token niemals in einem GitHub-Issue, Screenshot, Forum, Terminal-Log oder Chat.
>
> Falls ein Token versehentlich veröffentlicht wurde, widerrufe ihn sofort über `@BotFather` und erstelle einen neuen Token.

<!-- SCREENSHOT 1
Datei: docs/images/telegram-botfather-token.png
Inhalt: BotFather nach erfolgreicher Bot-Erstellung.
Der echte Token muss im Screenshot vollständig unkenntlich gemacht werden.
-->

---

### 2. Telegram-Kanal erstellen

Erstelle in Telegram einen neuen Kanal.

Der Name des Kanals ist frei wählbar.

Beispiel:

```text
APTGRAM Updates
```

Der Kanal kann öffentlich oder privat sein.

APTGRAM benötigt lediglich die Möglichkeit, Nachrichten über den zuvor erstellten Bot in diesem Kanal zu veröffentlichen.

---

### 3. Telegram-Bot als Administrator hinzufügen

Öffne die Einstellungen deines Telegram-Kanals.

Suche dort nach:

```text
Administratoren
```

oder bei englischer Telegram-Oberfläche:

```text
Administrators
```

Füge anschließend den zuvor erstellten Bot als Administrator hinzu.

Suche dazu nach seinem Benutzernamen.

Beispiel:

```text
@my_aptgram_bot
```

Der Bot benötigt mindestens die Berechtigung, Nachrichten im Kanal zu veröffentlichen.

Andere Administratorrechte werden von APTGRAM nicht benötigt.

<!-- SCREENSHOT 2
Datei: docs/images/telegram-channel-admin.png
Inhalt: Telegram-Kanalverwaltung mit dem APTGRAM-Bot als Administrator.
Die Berechtigung zum Veröffentlichen von Nachrichten sollte sichtbar sein.
-->

Nachdem der Bot hinzugefügt wurde, sende selbst eine neue Nachricht in den Kanal.

Zum Beispiel:

```text
APTGRAM setup
```

Wichtig ist, dass diese Nachricht **nach dem Hinzufügen des Bots** gesendet wird.

Telegram kann dadurch dem Bot ein neues Kanal-Update bereitstellen.

---

### 4. Telegram Chat ID des Kanals ermitteln

APTGRAM benötigt die numerische Chat ID des Telegram-Kanals.

Eine Kanal-ID sieht zum Beispiel so aus:

```text
-1001234567890
```

Öffne auf dem Debian-basierten Linux-System, auf dem APTGRAM installiert werden soll, ein Terminal.

Kopiere den folgenden Befehl vollständig in das Terminal:

```bash
read -rsp "Telegram Bot Token: " BOT_TOKEN
printf '\n'

printf 'url = "https://api.telegram.org/bot%s/getUpdates"\n' "${BOT_TOKEN}" |
    curl \
        --disable \
        --silent \
        --show-error \
        --config - |
    grep -o -- '-100[0-9]\+' |
    sort -u

unset BOT_TOKEN
```

Das Terminal fragt nun nach:

```text
Telegram Bot Token:
```

Füge den Bot Token ein, den du von `@BotFather` erhalten hast.

Während der Eingabe werden keine Zeichen angezeigt.

Das ist normal und verhindert, dass der Token offen im Terminal dargestellt wird.

Drücke anschließend `Enter`.

Nun sollte die numerische Chat ID deines Telegram-Kanals angezeigt werden.

Beispiel:

```text
-1001234567890
```

Kopiere die vollständige Nummer einschließlich des Minuszeichens.

Du benötigst sie gleich während der APTGRAM-Installation.

<!-- SCREENSHOT 3
Datei: docs/images/telegram-chat-id.png
Inhalt: Terminal nach erfolgreicher Ermittlung der Chat ID.
Der Bot Token darf nicht sichtbar sein.
Die ausgegebene -100... Chat ID darf sichtbar sein.
-->

#### Es wird keine Chat ID angezeigt?

Prüfe zunächst folgende Punkte:

1. Der Bot wurde dem richtigen Telegram-Kanal hinzugefügt.
2. Der Bot ist Administrator des Kanals.
3. Der Bot darf Nachrichten veröffentlichen.
4. Nach dem Hinzufügen des Bots wurde eine neue Nachricht im Kanal veröffentlicht.

Sende anschließend erneut eine Nachricht in den Telegram-Kanal.

Führe danach den Befehl zur Ermittlung der Chat ID noch einmal aus.

---

### 5. APTGRAM herunterladen

Öffne ein Terminal auf dem System, auf dem APTGRAM installiert werden soll.

Falls `git` noch nicht installiert ist, kannst du es unter Debian-basierten Systemen mit folgendem Befehl installieren:

```bash
sudo apt update
sudo apt install git
```

Klone anschließend das APTGRAM-Repository von GitHub:

```bash
git clone https://github.com/madebyzwen/aptgram.git
```

Wechsle in das heruntergeladene Projektverzeichnis:

```bash
cd aptgram
```

---

### 6. APTGRAM installieren

Starte den Installer mit:

```bash
bash install.sh
```

Der Installer sollte nicht mit `sudo bash install.sh` gestartet werden.

APTGRAM fordert selbst `sudo`-Berechtigungen an, sobald diese für die Installation benötigt werden.

Beim Start erkennt APTGRAM automatisch die Sprache des Systems.

Beispiel:

```text
APTGRAM Installation
==============================

Erkannte Sprache: Deutsch

Möchtest du die Sprache ändern? [j/N]
```

Drücke einfach `Enter`, um die erkannte Sprache zu verwenden.

Alternativ kannst du die Sprache während der Installation ändern.

---

### 7. Telegram Bot Token eingeben

APTGRAM fragt nach dem Telegram Bot Token:

```text
Telegram Bot Token:
```

Füge den vollständigen Token ein, den du zuvor von `@BotFather` erhalten hast.

APTGRAM prüft den Token direkt über Telegram.

Bei einem gültigen Token erscheint:

```text
Bot Token wird geprüft...
Bot Token erfolgreich geprüft.
```

Ist der Token ungültig, fordert APTGRAM dich zur erneuten Eingabe auf.

---

### 8. Telegram Chat ID eingeben

Anschließend fragt APTGRAM nach der Telegram Chat ID:

```text
Telegram Chat ID:
```

Füge die zuvor ermittelte Kanal-ID ein.

Beispiel:

```text
-1001234567890
```

Das Minuszeichen am Anfang gehört zur Chat ID und darf nicht entfernt werden.

APTGRAM testet anschließend automatisch die Verbindung zu Telegram.

Bei erfolgreicher Verbindung erscheint:

```text
Telegram-Verbindung wird getestet...
Telegram-Verbindung erfolgreich.
```

Öffne jetzt deinen Telegram-Kanal.

Dort sollte eine Testnachricht von APTGRAM angekommen sein.

<!-- SCREENSHOT 4
Datei: docs/images/telegram-test-message.png
Inhalt: Telegram-Kanal mit der erfolgreichen APTGRAM-Testnachricht.
Idealerweise Bot-Name und Testnachricht sichtbar.
-->

Wurde die Testnachricht empfangen, ist die Telegram-Konfiguration erfolgreich abgeschlossen.

---

### 9. Tägliche Prüfzeit festlegen

APTGRAM fragt nun nach der Uhrzeit für die tägliche Update-Prüfung.

Standardmäßig wird `20:00` Uhr vorgeschlagen:

```text
Tägliche Prüfzeit [20:00]:
```

Drücke einfach `Enter`, um die Standardzeit zu übernehmen.

Alternativ kannst du eine eigene Uhrzeit im 24-Stunden-Format eingeben.

Beispiel:

```text
06:30
```

APTGRAM führt den automatischen Update-Check dann täglich zu dieser Uhrzeit aus.

---

### 10. Konfiguration prüfen

Vor der eigentlichen Installation zeigt APTGRAM eine Zusammenfassung der Konfiguration an.

Beispiel:

```text
Konfiguration
==============================

Sprache: Deutsch
Telegram Chat ID: -1001234567890
Tägliche Prüfung: 20:00
Telegram Bot Token: erfolgreich geprüft
```

Der vollständige Telegram Bot Token wird in dieser Zusammenfassung nicht erneut benötigt.

---

### 11. Automatische Installation

APTGRAM führt nun die restliche Installation automatisch durch.

Dabei werden:

- die APTGRAM-Programmdateien installiert
- die APTGRAM-Bibliotheken installiert
- die Sprachdateien installiert
- die ausgewählte Sprache gespeichert
- die Telegram Chat ID gespeichert
- der Telegram Bot Token geschützt als systemd-Credential gespeichert
- ein `systemd`-Service eingerichtet
- ein `systemd`-Timer eingerichtet
- der Timer automatisch aktiviert
- ein erster APTGRAM-Prüflauf gestartet

Während der Installation erscheinen entsprechende Statusmeldungen.

Beispiel:

```text
APTGRAM-Dateien werden installiert...

systemd-Service und Timer werden installiert...

APTGRAM-Timer wird aktiviert...

Erster APTGRAM-Prüflauf wird gestartet...
```

Nach erfolgreicher Installation erscheint:

```text
APTGRAM wurde erfolgreich installiert.
```

---

### 12. Ersten APTGRAM-Bericht prüfen

Direkt nach der Installation startet APTGRAM automatisch einen ersten Prüflauf.

Sind Paketupdates verfügbar, sendet APTGRAM eine Übersicht an den konfigurierten Telegram-Kanal.

Die Nachricht enthält unter anderem die Anzahl der:

- Sicherheitsupdates
- regulären Updates
- Backports
- Updates aus externen Paketquellen
- Kernel-Updates

Zusätzlich sendet APTGRAM einen detaillierten Update-Bericht als Textdatei an den Telegram-Kanal.

Damit ist gleichzeitig geprüft, dass:

- APT korrekt abgefragt werden kann
- Updates erkannt werden
- Paketquellen analysiert werden
- Telegram erreichbar ist
- der Bot Nachrichten senden kann
- Dateianhänge an Telegram übertragen werden können

---

### 13. APTGRAM-Installation prüfen

Prüfe, ob der APTGRAM-Timer aktiviert ist:

```bash
systemctl is-enabled aptgram.timer
```

Die erwartete Ausgabe lautet:

```text
enabled
```

Die nächste geplante Ausführung kannst du mit folgendem Befehl anzeigen:

```bash
systemctl list-timers aptgram.timer
```

Die letzten Meldungen des APTGRAM-Service können mit folgendem Befehl angezeigt werden:

```bash
journalctl -u aptgram.service --no-pager -n 50
```

> [!NOTE]
> `aptgram.service` ist ein `oneshot`-Service.
>
> Der Service führt den APTGRAM-Prüflauf aus und beendet sich anschließend wieder.
>
> Deshalb bleibt der Service nach einem erfolgreichen Prüflauf nicht dauerhaft als `active (running)` aktiv. Das ist normal.

---

## Deinstallation

APTGRAM installiert automatisch einen eigenen Uninstaller.

Die vollständige Deinstallation wird mit folgendem Befehl gestartet:

```bash
sudo aptgram-uninstall
```

APTGRAM fragt vor der Deinstallation nach einer Bestätigung.

Beispiel:

```text
APTGRAM Deinstallation
==============================

Möchtest du APTGRAM vollständig entfernen? [j/N]
```

Bestätige die Deinstallation mit:

```text
j
```

Der Uninstaller:

- stoppt den APTGRAM-Timer
- deaktiviert den APTGRAM-Timer
- stoppt den APTGRAM-Service
- entfernt die `systemd`-Units
- entfernt die APTGRAM-Programmdateien
- entfernt die APTGRAM-Bibliotheken
- entfernt die Sprachdateien
- entfernt die APTGRAM-Konfiguration
- entfernt die gespeicherten Telegram-Credentials
- entfernt den APTGRAM-Uninstaller

Nach erfolgreicher Deinstallation erscheint:

```text
APTGRAM wurde vollständig entfernt.
```

APTGRAM hinterlässt anschließend keine installierten Programmdateien, Konfigurationsdateien oder `systemd`-Units auf dem System.

[Zurück zur Sprachauswahl](#documentation-languages)

---

<a id="italiano"></a>
