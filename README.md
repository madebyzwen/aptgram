<p align="center">
  <img
    src="docs/images/logo.png"
    alt="MADE by ZWEN"
    width="220"
  >
</p>

<h1 align="center">APTGRAM</h1>

<p align="center">
  <strong>APT package update monitoring with Telegram notifications.</strong>
</p>

<p align="center">
  Monitor available APT updates, classify security and repository sources,
  and receive clear reports directly in Telegram.
</p>

<p align="center">
  Designed for <strong>Debian-based Linux systems</strong>
  using <strong>systemd</strong> and the <strong>APT package manager</strong>.
</p>

<p align="center">
  Created by <strong>Sven Hüttmann</strong><br>
  <a href="https://madebyzwen.dev">madebyzwen.dev</a>
</p>

---

## Preview

<p align="center">
  <strong>
    APTGRAM delivers a compact update overview directly to Telegram
    and attaches a detailed plain-text package report.
  </strong>
</p>

<table>
  <tr>
    <td width="50%" align="center" valign="top">
      <img
        src="docs/images/telegram-notification.png"
        alt="APTGRAM Telegram update notification"
        width="360"
      >
      <br><br>
      <strong>Telegram Update Overview</strong>
      <br>
      <sub>
        Available updates are classified by security relevance,
        regular updates, backports, external sources, and kernel packages.
      </sub>
    </td>
    <td width="50%" align="center" valign="top">
      <img
        src="docs/images/update-report.png"
        alt="APTGRAM detailed update report"
        width="360"
      >
      <br><br>
      <strong>Detailed Package Report</strong>
      <br>
      <sub>
        A full plain-text report lists packages, installed and available
        versions, package summaries, and the source of each candidate version.
      </sub>
    </td>
  </tr>
</table>

---

<a id="documentation-languages"></a>

<h2 align="center">Documentation</h2>

<p align="center">
  <a href="#english">English</a> ·
  <a href="#francais">Français</a> ·
  <a href="#deutsch">Deutsch</a> ·
  <a href="#italiano">Italiano</a> ·
  <a href="#portugues-brasil">Português (Brasil)</a> ·
  <a href="#espanol">Español</a>
</p>

---

<a id="english"></a>

## System requirements

APTGRAM is designed for Debian-based Linux systems with:

- systemd
- APT package management
- internet access for package and APTGRAM version checks
- a Telegram bot and Telegram chat or channel

## Installation

Clone the repository and start the interactive installer:

```bash
git clone https://github.com/madebyzwen/aptgram.git
cd aptgram
bash install.sh
```

The installer guides you through language selection, Telegram Bot Token, Telegram Chat ID and the daily check time.
A Telegram test message is sent during installation.

For the detailed step-by-step guide, including Telegram bot and channel setup:

- [🇩🇪 Ausführliche Installation auf Deutsch](docs/INSTALLATION_DE.md)

## Updating APTGRAM

APTGRAM checks for new APTGRAM releases during its daily scheduled run.
For each newly available version, a separate Telegram notification is sent once.

To install an available APTGRAM update on the server:

```bash
sudo aptgram-update
```

## Uninstallation

To remove APTGRAM completely:

```bash
sudo aptgram-uninstall
```

## Features

APTGRAM monitors available APT package updates and sends clear update notifications directly to Telegram.

It provides:

- Automatic APT package list refresh
- Detection of available package updates
- Classification of security updates
- Classification of regular updates
- Detection of backports
- Detection of updates from external repositories
- Detection of kernel-related package updates
- Repository origin and archive analysis
- Package summary collection
- Detailed plain-text update reports
- Telegram update notifications
- Update reports sent as Telegram documents
- Weekly heartbeat notifications to confirm that APTGRAM is still running and able to reach Telegram
- Multi-language installer, notifications, and reports
- Secure Telegram bot token handling using systemd credentials
- Support for encrypted systemd credentials where available
- Automatic execution using a systemd timer

## Heartbeat

APTGRAM sends a weekly heartbeat message to Telegram.

The heartbeat acts as a simple health indicator and confirms that APTGRAM is still running and able to communicate with Telegram, even when there are no update notifications to send.

## Supported Languages

APTGRAM currently supports the following languages:

- English (`en`)
- French (`fr`)
- German (`de`)
- Italian (`it`)
- Portuguese — Brazil (`pt_BR`)
- Spanish (`es`)

The selected language is used throughout APTGRAM, including the installer, Telegram update notifications, weekly heartbeat messages, and generated update reports.

The installer automatically detects the system language where possible and allows the user to select a different supported language during setup.

## Localization Tools

APTGRAM includes development tools for maintaining its language files:

- Validation of locale variable completeness
- Detection of missing translation variables per locale
- Consistent sorting of locale variables
- Interactive addition of new locale variables and translations

All locale files are expected to contain the same set of translation variables.

[Back to language selection](#documentation-languages)

---


## Other languages

The project overview is also available in the following languages.


<a id="deutsch"></a>

<details>
<summary><strong>🇩🇪 Deutsch</strong></summary>

### Funktionen

APTGRAM überwacht verfügbare APT-Paketupdates und sendet übersichtliche Update-Benachrichtigungen direkt an Telegram.

APTGRAM bietet:

- Automatische Aktualisierung der APT-Paketlisten
- Erkennung verfügbarer Paketupdates
- Klassifizierung von Sicherheitsupdates
- Klassifizierung regulärer Updates
- Erkennung von Backports
- Erkennung von Updates aus externen Paketquellen
- Erkennung von Kernel-bezogenen Paketupdates
- Analyse von Repository-Herkunft und Archiv
- Erfassung von Paketbeschreibungen
- Detaillierte Update-Berichte als reine Textdateien
- Update-Benachrichtigungen über Telegram
- Versand von Update-Berichten als Telegram-Dokumente
- Wöchentliche Heartbeat-Benachrichtigungen zur Bestätigung, dass APTGRAM weiterhin läuft und Telegram erreichen kann
- Mehrsprachiger Installer, Benachrichtigungen und Berichte
- Sichere Verwaltung des Telegram-Bot-Tokens über systemd-Credentials
- Unterstützung verschlüsselter systemd-Credentials, sofern verfügbar
- Automatische Ausführung über einen systemd-Timer

### Heartbeat

APTGRAM sendet einmal pro Woche eine Heartbeat-Nachricht an Telegram.

Der Heartbeat dient als einfacher Funktionsindikator und bestätigt, dass APTGRAM weiterhin läuft und mit Telegram kommunizieren kann, auch wenn keine Update-Benachrichtigungen versendet werden müssen.

### Unterstützte Sprachen

APTGRAM unterstützt derzeit die folgenden Sprachen:

- Englisch (`en`)
- Französisch (`fr`)
- Deutsch (`de`)
- Italienisch (`it`)
- Portugiesisch — Brasilien (`pt_BR`)
- Spanisch (`es`)

Die ausgewählte Sprache wird in APTGRAM durchgängig verwendet. Dazu gehören der Installer, Telegram-Update-Benachrichtigungen, wöchentliche Heartbeat-Nachrichten und generierte Update-Berichte.

Der Installer erkennt nach Möglichkeit automatisch die Systemsprache und ermöglicht während der Einrichtung die Auswahl einer anderen unterstützten Sprache.

### Lokalisierungswerkzeuge

APTGRAM enthält Entwicklungswerkzeuge zur Pflege der Sprachdateien:

- Prüfung der Vollständigkeit von Locale-Variablen
- Erkennung fehlender Übersetzungsvariablen pro Sprache
- Einheitliche Sortierung der Locale-Variablen
- Interaktives Hinzufügen neuer Locale-Variablen und Übersetzungen

Alle Locale-Dateien müssen denselben Satz an Übersetzungsvariablen enthalten.

</details>


<a id="francais"></a>

<details>
<summary><strong>🇫🇷 Français</strong></summary>

### Fonctionnalités

APTGRAM surveille les mises à jour de paquets APT disponibles et envoie des notifications claires directement dans Telegram.

Il propose les fonctionnalités suivantes :

- Actualisation automatique des listes de paquets APT
- Détection des mises à jour de paquets disponibles
- Classification des mises à jour de sécurité
- Classification des mises à jour régulières
- Détection des backports
- Détection des mises à jour provenant de dépôts externes
- Détection des mises à jour de paquets liées au noyau
- Analyse de l'origine et de l'archive des dépôts
- Collecte des résumés de paquets
- Rapports détaillés de mises à jour en texte brut
- Notifications de mises à jour via Telegram
- Envoi des rapports de mises à jour sous forme de documents Telegram
- Notifications heartbeat hebdomadaires confirmant qu'APTGRAM fonctionne toujours et peut joindre Telegram
- Programme d'installation, notifications et rapports multilingues
- Gestion sécurisée du token du bot Telegram à l'aide des credentials systemd
- Prise en charge des credentials systemd chiffrés lorsqu'ils sont disponibles
- Exécution automatique à l'aide d'un timer systemd

### Heartbeat

APTGRAM envoie un message heartbeat hebdomadaire dans Telegram.

Le heartbeat sert d'indicateur de fonctionnement simple et confirme qu'APTGRAM est toujours actif et capable de communiquer avec Telegram, même lorsqu'aucune notification de mise à jour ne doit être envoyée.

### Langues prises en charge

APTGRAM prend actuellement en charge les langues suivantes :

- Anglais (`en`)
- Français (`fr`)
- Allemand (`de`)
- Italien (`it`)
- Portugais — Brésil (`pt_BR`)
- Espagnol (`es`)

La langue sélectionnée est utilisée dans l'ensemble d'APTGRAM, notamment dans le programme d'installation, les notifications de mises à jour Telegram, les messages heartbeat hebdomadaires et les rapports de mises à jour générés.

Le programme d'installation détecte automatiquement la langue du système lorsque cela est possible et permet à l'utilisateur de sélectionner une autre langue prise en charge pendant la configuration.

### Outils de localisation

APTGRAM comprend des outils de développement pour gérer ses fichiers de langue :

- Validation de l'exhaustivité des variables de langue
- Détection des variables de traduction manquantes pour chaque langue
- Tri cohérent des variables de langue
- Ajout interactif de nouvelles variables de langue et de leurs traductions

Tous les fichiers de langue doivent contenir le même ensemble de variables de traduction.

[Retour à la sélection de la langue](#documentation-languages)

---


</details>


<a id="italiano"></a>

<details>
<summary><strong>🇮🇹 Italiano</strong></summary>

### Funzionalità

APTGRAM monitora gli aggiornamenti disponibili dei pacchetti APT e invia notifiche chiare direttamente su Telegram.

APTGRAM offre:

- Aggiornamento automatico degli elenchi dei pacchetti APT
- Rilevamento degli aggiornamenti dei pacchetti disponibili
- Classificazione degli aggiornamenti di sicurezza
- Classificazione degli aggiornamenti regolari
- Rilevamento dei backport
- Rilevamento degli aggiornamenti provenienti da repository esterni
- Rilevamento degli aggiornamenti dei pacchetti relativi al kernel
- Analisi dell'origine e dell'archivio dei repository
- Raccolta dei riepiloghi dei pacchetti
- Report dettagliati degli aggiornamenti in formato testo semplice
- Notifiche degli aggiornamenti tramite Telegram
- Invio dei report degli aggiornamenti come documenti Telegram
- Notifiche heartbeat settimanali per confermare che APTGRAM sia ancora in esecuzione e possa raggiungere Telegram
- Installer, notifiche e report multilingue
- Gestione sicura del token del bot Telegram tramite credenziali systemd
- Supporto per credenziali systemd crittografate, quando disponibili
- Esecuzione automatica tramite un timer systemd

### Heartbeat

APTGRAM invia un messaggio heartbeat settimanale su Telegram.

L'heartbeat funge da semplice indicatore di funzionamento e conferma che APTGRAM sia ancora attivo e in grado di comunicare con Telegram, anche quando non ci sono notifiche di aggiornamento da inviare.

### Lingue supportate

APTGRAM supporta attualmente le seguenti lingue:

- Inglese (`en`)
- Francese (`fr`)
- Tedesco (`de`)
- Italiano (`it`)
- Portoghese — Brasile (`pt_BR`)
- Spagnolo (`es`)

La lingua selezionata viene utilizzata in tutto APTGRAM, inclusi l'installer, le notifiche degli aggiornamenti Telegram, i messaggi heartbeat settimanali e i report degli aggiornamenti generati.

L'installer rileva automaticamente la lingua del sistema quando possibile e consente all'utente di selezionare un'altra lingua supportata durante la configurazione.

### Strumenti di localizzazione

APTGRAM include strumenti di sviluppo per la manutenzione dei file di lingua:

- Verifica della completezza delle variabili di localizzazione
- Rilevamento delle variabili di traduzione mancanti per ogni lingua
- Ordinamento coerente delle variabili di localizzazione
- Aggiunta interattiva di nuove variabili di localizzazione e traduzioni

Tutti i file di lingua devono contenere lo stesso insieme di variabili di traduzione.

[Torna alla selezione della lingua](#documentation-languages)

---


</details>


<a id="portugues-brasil"></a>

<details>
<summary><strong>🇧🇷 Português (Brasil)</strong></summary>

### Recursos

O APTGRAM monitora as atualizações disponíveis de pacotes APT e envia notificações claras diretamente para o Telegram.

O APTGRAM oferece:

- Atualização automática das listas de pacotes APT
- Detecção de atualizações de pacotes disponíveis
- Classificação de atualizações de segurança
- Classificação de atualizações regulares
- Detecção de backports
- Detecção de atualizações provenientes de repositórios externos
- Detecção de atualizações de pacotes relacionadas ao kernel
- Análise da origem e do arquivo dos repositórios
- Coleta de resumos dos pacotes
- Relatórios detalhados de atualizações em texto simples
- Notificações de atualizações pelo Telegram
- Envio de relatórios de atualização como documentos do Telegram
- Notificações heartbeat semanais para confirmar que o APTGRAM continua em execução e consegue acessar o Telegram
- Instalador, notificações e relatórios multilíngues
- Gerenciamento seguro do token do bot do Telegram usando credenciais do systemd
- Suporte a credenciais criptografadas do systemd, quando disponíveis
- Execução automática usando um timer do systemd

### Heartbeat

O APTGRAM envia uma mensagem heartbeat semanal para o Telegram.

O heartbeat funciona como um indicador simples de funcionamento e confirma que o APTGRAM continua ativo e consegue se comunicar com o Telegram, mesmo quando não há notificações de atualização para enviar.

### Idiomas suportados

O APTGRAM atualmente oferece suporte aos seguintes idiomas:

- Inglês (`en`)
- Francês (`fr`)
- Alemão (`de`)
- Italiano (`it`)
- Português — Brasil (`pt_BR`)
- Espanhol (`es`)

O idioma selecionado é usado em todo o APTGRAM, incluindo o instalador, as notificações de atualização do Telegram, as mensagens heartbeat semanais e os relatórios de atualização gerados.

O instalador detecta automaticamente o idioma do sistema quando possível e permite que o usuário selecione outro idioma compatível durante a configuração.

### Ferramentas de localização

O APTGRAM inclui ferramentas de desenvolvimento para manutenção dos arquivos de idioma:

- Validação da integridade das variáveis de localização
- Detecção de variáveis de tradução ausentes por idioma
- Ordenação consistente das variáveis de localização
- Adição interativa de novas variáveis de localização e traduções

Todos os arquivos de idioma devem conter o mesmo conjunto de variáveis de tradução.

[Voltar para a seleção de idioma](#documentation-languages)

---


</details>


<a id="espanol"></a>

<details>
<summary><strong>🇪🇸 Español</strong></summary>

### Funciones

APTGRAM supervisa las actualizaciones disponibles de paquetes APT y envía notificaciones claras directamente a Telegram.

APTGRAM ofrece:

- Actualización automática de las listas de paquetes APT
- Detección de actualizaciones de paquetes disponibles
- Clasificación de actualizaciones de seguridad
- Clasificación de actualizaciones regulares
- Detección de backports
- Detección de actualizaciones procedentes de repositorios externos
- Detección de actualizaciones de paquetes relacionadas con el kernel
- Análisis del origen y del archivo de los repositorios
- Recopilación de resúmenes de paquetes
- Informes detallados de actualizaciones en texto sin formato
- Notificaciones de actualizaciones mediante Telegram
- Envío de informes de actualización como documentos de Telegram
- Notificaciones heartbeat semanales para confirmar que APTGRAM sigue funcionando y puede conectarse con Telegram
- Instalador, notificaciones e informes multilingües
- Gestión segura del token del bot de Telegram mediante credenciales de systemd
- Compatibilidad con credenciales cifradas de systemd cuando estén disponibles
- Ejecución automática mediante un temporizador de systemd

### Heartbeat

APTGRAM envía un mensaje heartbeat semanal a Telegram.

El heartbeat actúa como un sencillo indicador de funcionamiento y confirma que APTGRAM sigue activo y puede comunicarse con Telegram, incluso cuando no hay notificaciones de actualizaciones que enviar.

### Idiomas compatibles

APTGRAM admite actualmente los siguientes idiomas:

- Inglés (`en`)
- Francés (`fr`)
- Alemán (`de`)
- Italiano (`it`)
- Portugués — Brasil (`pt_BR`)
- Español (`es`)

El idioma seleccionado se utiliza en todo APTGRAM, incluido el instalador, las notificaciones de actualizaciones de Telegram, los mensajes heartbeat semanales y los informes de actualizaciones generados.

El instalador detecta automáticamente el idioma del sistema cuando es posible y permite al usuario seleccionar otro idioma compatible durante la configuración.

### Herramientas de localización

APTGRAM incluye herramientas de desarrollo para mantener sus archivos de idioma:

- Validación de la integridad de las variables de localización
- Detección de variables de traducción ausentes por idioma
- Ordenación coherente de las variables de localización
- Adición interactiva de nuevas variables de localización y traducciones

Todos los archivos de idioma deben contener el mismo conjunto de variables de traducción.

[Volver a la selección de idioma](#documentation-languages)

---

</details>

<p align="center">
  Created by <strong>Sven Hüttmann</strong>
  ·
  <a href="https://madebyzwen.dev">madebyzwen.dev</a>
</p>
