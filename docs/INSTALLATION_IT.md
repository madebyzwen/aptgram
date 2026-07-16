# APTGRAM – Installazione in italiano

[← Torna al README](../README.md)

Questa guida illustra passo dopo passo come configurare il bot Telegram, il canale Telegram e installare APTGRAM.

## Installazione

APTGRAM è progettato per sistemi Linux basati su Debian con `systemd` e il gestore di pacchetti APT.

Ad esempio:

- Debian
- Ubuntu
- sistemi server basati su Debian
- sistemi NAS UGREEN compatibili con UGOS Pro

Sono inoltre necessari:

- un bot Telegram
- un canale Telegram per le notifiche di APTGRAM
- il **Telegram Bot Token**
- il **Telegram Chat ID** numerico del canale

Non hai mai creato un bot Telegram?

Nessun problema. I passaggi seguenti ti guideranno attraverso l'intera configurazione.

---

### 1. Creare un bot Telegram

Apri Telegram e cerca:

```text
@BotFather
```

Assicurati di utilizzare il BotFather ufficiale di Telegram.

Apri la chat e invia:

```text
/newbot
```

BotFather ti guiderà ora nella creazione del bot.

#### Scegliere il nome del bot

Per prima cosa, BotFather chiede un nome per il bot.

Questo nome verrà successivamente visualizzato in Telegram.

Esempio:

```text
APTGRAM Server
```

Il nome può essere scelto liberamente.

#### Scegliere il nome utente del bot

Successivamente, il bot necessita di un nome utente univoco.

Il nome utente deve terminare con `bot`.

Esempio:

```text
my_aptgram_bot
```

Se il nome utente è già utilizzato, devi sceglierne un altro.

Dopo la corretta creazione del bot, BotFather mostra il **Telegram Bot Token**.

Un bot token ha un aspetto simile a questo:

```text
1234567890:AAExampleTokenDoNotUseThisValue
```

Copia il token completo.

Ti servirà in seguito durante l'installazione di APTGRAM.

> [!IMPORTANT]
> Il Telegram Bot Token è un dato segreto e deve essere trattato come una password.
>
> Non pubblicare mai il token in una issue di GitHub, uno screenshot, un forum, un log del terminale o una chat.
>
> Se un token viene pubblicato accidentalmente, revocalo immediatamente tramite `@BotFather` e creane uno nuovo.

![BotFather dopo la corretta creazione del bot Telegram](images/telegram-botfather-token.png)


---

### 2. Creare un canale Telegram

Crea un nuovo canale in Telegram.

Il nome del canale può essere scelto liberamente.

Esempio:

```text
APTGRAM Updates
```

Il canale può essere pubblico o privato.

APTGRAM deve solamente poter pubblicare messaggi in questo canale tramite il bot creato in precedenza.

---

### 3. Aggiungere il bot Telegram come amministratore

Apri le impostazioni del tuo canale Telegram.

Cerca:

```text
Amministratori
```

o, se l'interfaccia di Telegram è in inglese:

```text
Administrators
```

Aggiungi quindi come amministratore il bot creato in precedenza.

Cercalo tramite il suo nome utente.

Esempio:

```text
@my_aptgram_bot
```

Il bot deve disporre almeno dell'autorizzazione a pubblicare messaggi nel canale.

APTGRAM non necessita di altri diritti di amministratore.

![Bot APTGRAM aggiunto come amministratore del canale Telegram](images/telegram-channel-admin.png)


---

### 4. Individuare il Telegram Chat ID del canale

APTGRAM necessita del Chat ID numerico del canale Telegram.

Un ID canale ha, ad esempio, questo aspetto:

```text
-1001234567890
```

Il modo più semplice per individuare l'ID del canale è tramite **Telegram Web**. Non sono necessari né un terminale né il bot token.

1. Apri nel browser:

   ```text
   https://web.telegram.org
   ```

2. Accedi con il tuo account Telegram.

3. Nella barra laterale sinistra, apri il canale Telegram che desideri utilizzare per APTGRAM.

4. Osserva quindi l'indirizzo nella barra degli indirizzi del browser.

L'indirizzo ha, ad esempio, questo aspetto:

```text
https://web.telegram.org/a/#-1001234567890
```

L'ID completo del canale si trova dopo il `#`:

```text
-1001234567890
```

Copia il numero completo, incluso il segno meno.

Ti servirà questo ID canale durante l'installazione di APTGRAM.

![Telegram Chat ID del canale in Telegram Web](images/telegram-chat-id.png)


#### L'ID del canale non viene visualizzato?

Verifica i seguenti punti:

1. Hai aperto il canale corretto in Telegram Web.
2. Non ti trovi in una chat privata con il bot.
3. Non hai aperto il gruppo di discussione collegato al canale.
4. Stai utilizzando l'indirizzo completo della barra degli indirizzi del browser.
5. L'ID canale copiato inizia con `-100`.

---

### 5. Scaricare APTGRAM

Apri un terminale sul sistema in cui deve essere installato APTGRAM.

Se `git` non è ancora installato, puoi installarlo sui sistemi basati su Debian con:

```bash
sudo apt update
sudo apt install git
```

Clona quindi il repository APTGRAM da GitHub:

```bash
git clone https://github.com/madebyzwen/aptgram.git
```

Passa alla directory del progetto scaricato:

```bash
cd aptgram
```

---

### 6. Installare APTGRAM

Avvia il programma di installazione con:

```bash
bash install.sh
```

Il programma di installazione non deve essere avviato con `sudo bash install.sh`.

APTGRAM richiede autonomamente i privilegi `sudo` non appena diventano necessari per l'installazione.

All'avvio, APTGRAM rileva automaticamente la lingua del sistema.

Esempio:

```text
Installazione di APTGRAM
==============================

Lingua rilevata: Italiano

Vuoi cambiare la lingua? [s/N]
```

Premi semplicemente `Invio` per utilizzare la lingua rilevata.

In alternativa, puoi cambiare la lingua durante l'installazione.

---

### 7. Inserire il Telegram Bot Token

APTGRAM richiede il Telegram Bot Token:

```text
Telegram Bot Token:
```

Incolla il token completo ricevuto da `@BotFather`.

APTGRAM verifica il token direttamente tramite Telegram.

Se il token è valido, viene visualizzato:

```text
Verifica del Bot Token...
Bot Token verificato correttamente.
```

Se il token non è valido, APTGRAM richiede di inserirlo nuovamente.

---

### 8. Inserire il Telegram Chat ID

Successivamente, APTGRAM richiede il Telegram Chat ID:

```text
Telegram Chat ID:
```

Incolla l'ID del canale individuato in precedenza.

Esempio:

```text
-1001234567890
```

Il segno meno all'inizio fa parte del Chat ID e non deve essere rimosso.

APTGRAM verifica quindi automaticamente la connessione a Telegram.

Se la connessione riesce, viene visualizzato:

```text
Verifica della connessione Telegram...
Connessione Telegram riuscita.
```

Apri ora il tuo canale Telegram.

Dovrebbe essere arrivato un messaggio di prova da APTGRAM.

![Messaggio di prova APTGRAM ricevuto correttamente nel canale Telegram](images/telegram-test-message.png)


Dopo aver ricevuto il messaggio di prova, la configurazione di Telegram è completata correttamente.

---

### 9. Impostare l'orario del controllo giornaliero

APTGRAM richiede ora l'orario del controllo giornaliero degli aggiornamenti.

Come valore predefinito viene proposto `20:00`:

```text
Orario del controllo giornaliero [20:00]:
```

Premi `Invio` per accettare l'orario predefinito.

In alternativa, puoi inserire un altro orario nel formato 24 ore.

Esempio:

```text
06:30
```

APTGRAM eseguirà il controllo automatico degli aggiornamenti ogni giorno a questo orario.

---

### 10. Verificare la configurazione

Prima dell'installazione vera e propria, APTGRAM mostra un riepilogo della configurazione.

Esempio:

```text
Configurazione
==============================

Lingua: Italiano
Telegram Chat ID: -1001234567890
Controllo giornaliero: 20:00
Telegram Bot Token: verificato correttamente
```

Il Telegram Bot Token completo non viene mostrato nuovamente in questo riepilogo.

---

### 11. Installazione automatica

APTGRAM esegue ora automaticamente il resto dell'installazione.

Durante il processo vengono:

- installati i file di programma di APTGRAM
- installate le librerie di APTGRAM
- installati i file di lingua
- salvata la lingua selezionata
- salvato il Telegram Chat ID
- salvato in modo protetto il Telegram Bot Token come credenziale systemd
- configurato un servizio `systemd`
- configurato un timer `systemd`
- attivato automaticamente il timer
- avviato un primo controllo APTGRAM

Durante l'installazione vengono visualizzati i relativi messaggi di stato.

Esempio:

```text
Installazione dei file APTGRAM...

Installazione del servizio e del timer systemd...

Attivazione del timer APTGRAM...

Avvio del primo controllo APTGRAM...
```

Dopo una corretta installazione viene visualizzato:

```text
APTGRAM è stato installato correttamente.
```

---

### 12. Verificare il primo rapporto APTGRAM

Subito dopo l'installazione, APTGRAM avvia automaticamente un primo controllo.

Se sono disponibili aggiornamenti dei pacchetti, APTGRAM invia un riepilogo al canale Telegram configurato.

Il messaggio contiene, tra l'altro, il numero di:

- aggiornamenti di sicurezza
- aggiornamenti regolari
- backport
- aggiornamenti provenienti da sorgenti di pacchetti esterne
- aggiornamenti del kernel

APTGRAM invia inoltre al canale Telegram un rapporto dettagliato degli aggiornamenti come file di testo.

In questo modo viene contemporaneamente verificato che:

- APT possa essere interrogato correttamente
- gli aggiornamenti vengano rilevati
- le sorgenti dei pacchetti vengano analizzate
- Telegram sia raggiungibile
- il bot possa inviare messaggi
- gli allegati possano essere trasferiti a Telegram

---

### 13. Verificare l'installazione di APTGRAM

Verifica se il timer APTGRAM è attivato:

```bash
systemctl is-enabled aptgram.timer
```

L'output previsto è:

```text
enabled
```

Puoi visualizzare la prossima esecuzione pianificata con:

```bash
systemctl list-timers aptgram.timer
```

Puoi visualizzare gli ultimi messaggi del servizio APTGRAM con:

```bash
journalctl -u aptgram.service --no-pager -n 50
```

> [!NOTE]
> `aptgram.service` è un servizio `oneshot`.
>
> Il servizio esegue il controllo APTGRAM e successivamente termina.
>
> Per questo motivo, dopo un controllo riuscito non rimane permanentemente `active (running)`. È normale.

---

## Disinstallazione

APTGRAM installa automaticamente un proprio programma di disinstallazione.

Avvia la disinstallazione completa con:

```bash
sudo aptgram-uninstall
```

APTGRAM richiede una conferma prima della disinstallazione.

Esempio:

```text
Disinstallazione di APTGRAM
==============================

Vuoi rimuovere completamente APTGRAM? [s/N]
```

Conferma la disinstallazione con:

```text
s
```

Il programma di disinstallazione:

- arresta il timer APTGRAM
- disattiva il timer APTGRAM
- arresta il servizio APTGRAM
- rimuove le unità `systemd`
- rimuove i file di programma di APTGRAM
- rimuove le librerie di APTGRAM
- rimuove i file di lingua
- rimuove la configurazione di APTGRAM
- rimuove le credenziali Telegram salvate
- rimuove il programma di disinstallazione di APTGRAM

Dopo una corretta disinstallazione viene visualizzato:

```text
APTGRAM è stato rimosso completamente.
```

APTGRAM non lascia sul sistema file di programma installati, file di configurazione o unità `systemd`.

[← Torna al README](../README.md)
