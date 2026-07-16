# APTGRAM – Installation in English

[← Back to the README](../README.md)

This guide walks you step by step through setting up the Telegram bot, the Telegram channel, and installing APTGRAM.

## Installation

APTGRAM is designed for Debian-based Linux systems with `systemd` and the APT package manager.

Examples include:

- Debian
- Ubuntu
- Debian-based server systems
- compatible UGREEN NAS systems with UGOS Pro

You will also need:

- a Telegram bot
- a Telegram channel for APTGRAM notifications
- the **Telegram Bot Token**
- the numeric **Telegram Chat ID** of the channel

Have you never created a Telegram bot before?

No problem. The following steps guide you through the complete setup.

---

### 1. Create a Telegram bot

Open Telegram and search for:

```text
@BotFather
```

Make sure you use Telegram's official BotFather.

Open the chat and send:

```text
/newbot
```

BotFather will now guide you through creating your bot.

#### Choose a bot name

BotFather first asks for a name for the bot.

This name will later be displayed in Telegram.

Example:

```text
APTGRAM Server
```

You may choose any name.

#### Choose a bot username

The bot then needs a unique username.

The username must end in `bot`.

Example:

```text
my_aptgram_bot
```

If the username is already taken, choose a different one.

After the bot has been created successfully, BotFather displays the **Telegram Bot Token**.

A bot token looks similar to this:

```text
1234567890:AAExampleTokenDoNotUseThisValue
```

Copy the complete token.

You will need it later during the APTGRAM installation.

> [!IMPORTANT]
> The Telegram Bot Token is a secret and must be treated like a password.
>
> Never publish the token in a GitHub issue, screenshot, forum, terminal log, or chat.
>
> If a token is accidentally exposed, revoke it immediately through `@BotFather` and create a new token.

![BotFather after successfully creating the Telegram bot](images/telegram-botfather-token.png)


---

### 2. Create a Telegram channel

Create a new channel in Telegram.

You may choose any channel name.

Example:

```text
APTGRAM Updates
```

The channel may be public or private.

APTGRAM only needs permission to publish messages in this channel through the bot you created previously.

---

### 3. Add the Telegram bot as an administrator

Open the settings of your Telegram channel.

Look for:

```text
Administrators
```

Add the bot you created previously as an administrator.

Search for its username.

Example:

```text
@my_aptgram_bot
```

The bot needs at least permission to publish messages in the channel.

APTGRAM does not require any other administrator permissions.

![APTGRAM bot added as an administrator of the Telegram channel](images/telegram-channel-admin.png)


---

### 4. Find the Telegram Chat ID of the channel

APTGRAM needs the numeric Chat ID of the Telegram channel.

A channel ID looks like this:

```text
-1001234567890
```

The easiest way to find the channel ID is through **Telegram Web**. You do not need a terminal or your bot token for this method.

1. Open the following address in your browser:

   ```text
   https://web.telegram.org
   ```

2. Sign in with your Telegram account.

3. In the left sidebar, open the Telegram channel you want to use for APTGRAM.

4. Look at the address in your browser's address bar.

The address should look similar to this:

```text
https://web.telegram.org/a/#-1001234567890
```

The complete channel ID appears after the `#`:

```text
-1001234567890
```

Copy the complete number, including the minus sign.

You will need this channel ID during the APTGRAM installation.

![Telegram Chat ID of the channel in Telegram Web](images/telegram-chat-id.png)


#### Is the channel ID not displayed?

Check the following:

1. You opened the correct channel in Telegram Web.
2. You are not in a private chat with the bot.
3. You did not open the discussion group linked to the channel.
4. You are using the complete address from the browser's address bar.
5. The copied channel ID begins with `-100`.

---

### 5. Download APTGRAM

Open a terminal on the system where APTGRAM will be installed.

If `git` is not installed yet, install it on a Debian-based system with:

```bash
sudo apt update
sudo apt install git
```

Then clone the APTGRAM repository from GitHub:

```bash
git clone https://github.com/madebyzwen/aptgram.git
```

Change to the downloaded project directory:

```bash
cd aptgram
```

---

### 6. Install APTGRAM

Start the installer with:

```bash
bash install.sh
```

Do not start the installer with `sudo bash install.sh`.

APTGRAM requests `sudo` privileges itself as soon as they are required for the installation.

When it starts, APTGRAM automatically detects the system language.

Example:

```text
APTGRAM Installation
==============================

Detected language: English

Would you like to change the language? [y/N]
```

Press `Enter` to use the detected language.

Alternatively, you can change the language during the installation.

---

### 7. Enter the Telegram Bot Token

APTGRAM asks for the Telegram Bot Token:

```text
Telegram Bot Token:
```

Paste the complete token you received from `@BotFather`.

APTGRAM checks the token directly through Telegram.

For a valid token, the following is displayed:

```text
Checking Bot Token...
Bot Token verified successfully.
```

If the token is invalid, APTGRAM asks you to enter it again.

---

### 8. Enter the Telegram Chat ID

APTGRAM then asks for the Telegram Chat ID:

```text
Telegram Chat ID:
```

Paste the channel ID you found earlier.

Example:

```text
-1001234567890
```

The minus sign at the beginning is part of the Chat ID and must not be removed.

APTGRAM then automatically tests the connection to Telegram.

For a successful connection, the following is displayed:

```text
Testing Telegram connection...
Telegram connection successful.
```

Now open your Telegram channel.

You should see a test message from APTGRAM.

![Successful APTGRAM test message in the Telegram channel](images/telegram-test-message.png)


Once the test message has been received, the Telegram configuration is complete.

---

### 9. Set the daily check time

APTGRAM now asks for the time of the daily update check.

The default is `20:00`:

```text
Daily check time [20:00]:
```

Press `Enter` to accept the default time.

Alternatively, enter a different time in 24-hour format.

Example:

```text
06:30
```

APTGRAM will then run the automatic update check every day at this time.

---

### 10. Review the configuration

Before the actual installation, APTGRAM displays a summary of the configuration.

Example:

```text
Configuration
==============================

Language: English
Telegram Chat ID: -1001234567890
Daily check: 20:00
Telegram Bot Token: verified successfully
```

The complete Telegram Bot Token is not displayed again in this summary.

---

### 11. Automatic installation

APTGRAM now performs the remaining installation steps automatically.

It will:

- install the APTGRAM program files
- install the APTGRAM libraries
- install the language files
- save the selected language
- save the Telegram Chat ID
- securely store the Telegram Bot Token as a systemd credential
- configure a `systemd` service
- configure a `systemd` timer
- automatically enable the timer
- start an initial APTGRAM check

Appropriate status messages are displayed during installation.

Example:

```text
Installing APTGRAM files...

Installing systemd service and timer...

Enabling APTGRAM timer...

Starting initial APTGRAM check...
```

After a successful installation, the following is displayed:

```text
APTGRAM was installed successfully.
```

---

### 12. Check the first APTGRAM report

APTGRAM automatically starts an initial check immediately after installation.

If package updates are available, APTGRAM sends a summary to the configured Telegram channel.

The message includes the number of:

- security updates
- regular updates
- backports
- updates from external package sources
- kernel updates

APTGRAM also sends a detailed update report as a text file to the Telegram channel.

This simultaneously verifies that:

- APT can be queried correctly
- updates are detected
- package sources are analyzed
- Telegram is reachable
- the bot can send messages
- file attachments can be transferred to Telegram

---

### 13. Verify the APTGRAM installation

Check whether the APTGRAM timer is enabled:

```bash
systemctl is-enabled aptgram.timer
```

The expected output is:

```text
enabled
```

Display the next scheduled run with:

```bash
systemctl list-timers aptgram.timer
```

Display the latest messages from the APTGRAM service with:

```bash
journalctl -u aptgram.service --no-pager -n 50
```

> [!NOTE]
> `aptgram.service` is a `oneshot` service.
>
> The service runs the APTGRAM check and then exits.
>
> It therefore does not remain permanently `active (running)` after a successful check. This is normal.

---

## Updating APTGRAM

APTGRAM checks for new APTGRAM releases during its daily scheduled run. For each newly available version, a separate Telegram notification is sent once.

Install an available update with:

```bash
sudo aptgram-update
```

The updater downloads the release package, verifies its SHA-256 checksum, validates the package contents, and creates a rollback backup before replacing program files. The configured language, Telegram chat or channel ID, Bot Token, credential mode, daily check time, and previous timer state are preserved.

If an update fails while files or systemd units are being replaced, APTGRAM attempts to restore the previous program and timer state.

When upgrading directly from APTGRAM 1.0.0 to 1.1.0, run `sudo aptgram-update` a second time after the first successful update. This installs the new `aptgram-config` command. Existing settings remain unchanged.

---

## Change the configuration after installation

An existing installation can be adjusted interactively:

```bash
sudo aptgram-config
```

The Telegram Bot Token, chat/channel ID, and daily check time can be changed or skipped independently. Values that are not selected remain unchanged.

The stored Bot Token is never displayed when APTGRAM asks whether it should be changed. A newly entered token is visible while it is being entered. New Bot Tokens and chat or channel IDs are verified with Telegram before they are saved.

Changing the daily check time updates and restarts the systemd timer and displays the next scheduled run. After successful changes, APTGRAM sends a final Telegram confirmation containing the changed setting names and the active daily check time.

---

## Sending a test heartbeat

The configured heartbeat message can be sent immediately:

```bash
sudo aptgram send-test-heartbeat
```

This command uses the existing configuration, language, Telegram credentials, and heartbeat message. It does not refresh APT package lists and does not perform an update check.

---

## Uninstallation

APTGRAM automatically installs its own uninstaller.

Start the complete uninstallation with:

```bash
sudo aptgram-uninstall
```

APTGRAM asks for confirmation before uninstalling.

Example:

```text
APTGRAM Uninstallation
==============================

Would you like to remove APTGRAM completely? [y/N]
```

Confirm the uninstallation with:

```text
y
```

The uninstaller:

- stops the APTGRAM timer
- disables the APTGRAM timer
- stops the APTGRAM service
- removes the `systemd` units
- removes the APTGRAM program files
- removes the APTGRAM libraries
- removes the language files
- removes the APTGRAM configuration
- removes the stored Telegram credentials
- removes the APTGRAM uninstaller

After a successful uninstallation, the following is displayed:

```text
APTGRAM was removed completely.
```

APTGRAM leaves no installed program files, configuration files, or `systemd` units on the system.

[← Back to the README](../README.md)
