# APTGRAM – Installation en français

[← Retour au README](../README.md)

Ce guide explique pas à pas comment configurer le bot Telegram, le canal Telegram et installer APTGRAM.

## Installation

APTGRAM est conçu pour les systèmes Linux basés sur Debian utilisant `systemd` et le gestionnaire de paquets APT.

Cela inclut par exemple :

- Debian
- Ubuntu
- les systèmes serveur basés sur Debian
- les systèmes NAS UGREEN compatibles avec UGOS Pro

Vous avez également besoin :

- d'un bot Telegram
- d'un canal Telegram pour les notifications APTGRAM
- du **Telegram Bot Token**
- du **Telegram Chat ID** numérique du canal

Vous n'avez encore jamais créé de bot Telegram ?

Aucun problème. Les étapes suivantes vous guideront tout au long de la configuration.

---

### 1. Créer un bot Telegram

Ouvrez Telegram et recherchez :

```text
@BotFather
```

Veillez à utiliser le BotFather officiel de Telegram.

Ouvrez la conversation et envoyez :

```text
/newbot
```

BotFather vous guide maintenant dans la création de votre bot.

#### Définir le nom du bot

BotFather vous demande d'abord un nom pour le bot.

Ce nom sera ensuite affiché dans Telegram.

Exemple :

```text
APTGRAM Server
```

Vous pouvez choisir librement ce nom.

#### Définir le nom d'utilisateur du bot

Le bot a ensuite besoin d'un nom d'utilisateur unique.

Le nom d'utilisateur doit se terminer par `bot`.

Exemple :

```text
my_aptgram_bot
```

Si le nom d'utilisateur est déjà utilisé, vous devez en choisir un autre.

Une fois le bot créé, BotFather affiche le **Telegram Bot Token**.

Un bot token ressemble à ceci :

```text
1234567890:AAExampleTokenDoNotUseThisValue
```

Copiez le token complet.

Vous en aurez besoin plus tard pendant l'installation d'APTGRAM.

> [!IMPORTANT]
> Le Telegram Bot Token est un secret et doit être traité comme un mot de passe.
>
> Ne publiez jamais ce token dans une issue GitHub, une capture d'écran, un forum, un journal de terminal ou une conversation.
>
> Si un token est publié accidentellement, révoquez-le immédiatement via `@BotFather` et créez-en un nouveau.

![BotFather après la création réussie du bot Telegram](images/telegram-botfather-token.png)


---

### 2. Créer un canal Telegram

Créez un nouveau canal dans Telegram.

Vous pouvez choisir librement le nom du canal.

Exemple :

```text
APTGRAM Updates
```

Le canal peut être public ou privé.

APTGRAM doit uniquement pouvoir publier des messages dans ce canal via le bot créé précédemment.

---

### 3. Ajouter le bot Telegram en tant qu'administrateur

Ouvrez les paramètres de votre canal Telegram.

Recherchez :

```text
Administrateurs
```

ou, si l'interface de Telegram est en anglais :

```text
Administrators
```

Ajoutez ensuite en tant qu'administrateur le bot créé précédemment.

Recherchez son nom d'utilisateur.

Exemple :

```text
@my_aptgram_bot
```

Le bot doit au minimum être autorisé à publier des messages dans le canal.

APTGRAM n'a besoin d'aucun autre droit d'administrateur.

![Bot APTGRAM ajouté comme administrateur du canal Telegram](images/telegram-channel-admin.png)


---

### 4. Déterminer le Telegram Chat ID du canal

APTGRAM a besoin du Chat ID numérique du canal Telegram.

Un identifiant de canal ressemble par exemple à ceci :

```text
-1001234567890
```

La méthode la plus simple pour trouver l'identifiant du canal consiste à utiliser **Telegram Web**. Vous n'avez besoin ni d'un terminal ni de votre bot token.

1. Ouvrez dans votre navigateur :

   ```text
   https://web.telegram.org
   ```

2. Connectez-vous avec votre compte Telegram.

3. Dans la barre latérale gauche, ouvrez le canal Telegram que vous souhaitez utiliser pour APTGRAM.

4. Regardez ensuite l'adresse affichée dans la barre d'adresse du navigateur.

L'adresse ressemble par exemple à ceci :

```text
https://web.telegram.org/a/#-1001234567890
```

L'identifiant complet du canal se trouve après le `#` :

```text
-1001234567890
```

Copiez le numéro complet, y compris le signe moins.

Vous aurez besoin de cet identifiant de canal pendant l'installation d'APTGRAM.

![Telegram Chat ID du canal dans Telegram Web](images/telegram-chat-id.png)


#### L'identifiant du canal n'est pas affiché ?

Vérifiez les points suivants :

1. Vous avez ouvert le bon canal dans Telegram Web.
2. Vous ne vous trouvez pas dans une conversation privée avec le bot.
3. Vous n'avez pas ouvert le groupe de discussion associé au canal.
4. Vous utilisez l'adresse complète de la barre d'adresse du navigateur.
5. L'identifiant de canal copié commence par `-100`.

---

### 5. Télécharger APTGRAM

Ouvrez un terminal sur le système où APTGRAM doit être installé.

Si `git` n'est pas encore installé, vous pouvez l'installer sur un système basé sur Debian avec :

```bash
sudo apt update
sudo apt install git
```

Clonez ensuite le dépôt APTGRAM depuis GitHub :

```bash
git clone https://github.com/madebyzwen/aptgram.git
```

Accédez au répertoire du projet téléchargé :

```bash
cd aptgram
```

---

### 6. Installer APTGRAM

Démarrez l'installateur avec :

```bash
bash install.sh
```

L'installateur ne doit pas être lancé avec `sudo bash install.sh`.

APTGRAM demande lui-même les droits `sudo` dès qu'ils sont nécessaires à l'installation.

Au démarrage, APTGRAM détecte automatiquement la langue du système.

Exemple :

```text
Installation d'APTGRAM
==============================

Langue détectée : Français

Souhaitez-vous changer de langue ? [o/N]
```

Appuyez simplement sur `Entrée` pour utiliser la langue détectée.

Vous pouvez également changer de langue pendant l'installation.

---

### 7. Saisir le Telegram Bot Token

APTGRAM demande le Telegram Bot Token :

```text
Telegram Bot Token:
```

Collez le token complet obtenu auprès de `@BotFather`.

APTGRAM vérifie directement le token via Telegram.

Pour un token valide, le message suivant s'affiche :

```text
Vérification du Bot Token...
Bot Token vérifié avec succès.
```

Si le token n'est pas valide, APTGRAM vous demande de le saisir à nouveau.

---

### 8. Saisir le Telegram Chat ID

APTGRAM demande ensuite le Telegram Chat ID :

```text
Telegram Chat ID:
```

Collez l'identifiant de canal déterminé précédemment.

Exemple :

```text
-1001234567890
```

Le signe moins au début fait partie du Chat ID et ne doit pas être supprimé.

APTGRAM teste ensuite automatiquement la connexion à Telegram.

Lorsque la connexion réussit, le message suivant s'affiche :

```text
Test de la connexion Telegram...
Connexion Telegram réussie.
```

Ouvrez maintenant votre canal Telegram.

Vous devriez y trouver un message de test envoyé par APTGRAM.

![Message de test APTGRAM reçu avec succès dans le canal Telegram](images/telegram-test-message.png)


Une fois le message de test reçu, la configuration de Telegram est terminée avec succès.

---

### 9. Définir l'heure de vérification quotidienne

APTGRAM demande maintenant l'heure de la vérification quotidienne des mises à jour.

Par défaut, `20:00` est proposé :

```text
Heure de vérification quotidienne [20:00] :
```

Appuyez sur `Entrée` pour conserver l'heure par défaut.

Vous pouvez également saisir une autre heure au format 24 heures.

Exemple :

```text
06:30
```

APTGRAM exécutera alors la vérification automatique des mises à jour chaque jour à cette heure.

---

### 10. Vérifier la configuration

Avant l'installation proprement dite, APTGRAM affiche un résumé de la configuration.

Exemple :

```text
Configuration
==============================

Langue : Français
Telegram Chat ID : -1001234567890
Vérification quotidienne : 20:00
Telegram Bot Token : vérifié avec succès
```

Le Telegram Bot Token complet n'est pas affiché à nouveau dans ce résumé.

---

### 11. Installation automatique

APTGRAM effectue maintenant automatiquement le reste de l'installation.

Les opérations suivantes sont effectuées :

- installation des fichiers du programme APTGRAM
- installation des bibliothèques APTGRAM
- installation des fichiers de langue
- enregistrement de la langue sélectionnée
- enregistrement du Telegram Chat ID
- stockage sécurisé du Telegram Bot Token en tant qu'identifiant systemd
- configuration d'un service `systemd`
- configuration d'un timer `systemd`
- activation automatique du timer
- lancement d'une première vérification APTGRAM

Des messages d'état correspondants s'affichent pendant l'installation.

Exemple :

```text
Installation des fichiers APTGRAM...

Installation du service et du timer systemd...

Activation du timer APTGRAM...

Démarrage de la première vérification APTGRAM...
```

Après une installation réussie, le message suivant s'affiche :

```text
APTGRAM a été installé avec succès.
```

---

### 12. Vérifier le premier rapport APTGRAM

Immédiatement après l'installation, APTGRAM lance automatiquement une première vérification.

Si des mises à jour de paquets sont disponibles, APTGRAM envoie un résumé au canal Telegram configuré.

Le message contient notamment le nombre de :

- mises à jour de sécurité
- mises à jour régulières
- backports
- mises à jour provenant de sources de paquets externes
- mises à jour du noyau

APTGRAM envoie également un rapport détaillé des mises à jour sous forme de fichier texte au canal Telegram.

Cela permet en même temps de vérifier que :

- APT peut être interrogé correctement
- les mises à jour sont détectées
- les sources de paquets sont analysées
- Telegram est accessible
- le bot peut envoyer des messages
- des pièces jointes peuvent être transférées vers Telegram

---

### 13. Vérifier l'installation d'APTGRAM

Vérifiez si le timer APTGRAM est activé :

```bash
systemctl is-enabled aptgram.timer
```

La sortie attendue est :

```text
enabled
```

Vous pouvez afficher la prochaine exécution planifiée avec :

```bash
systemctl list-timers aptgram.timer
```

Vous pouvez afficher les derniers messages du service APTGRAM avec :

```bash
journalctl -u aptgram.service --no-pager -n 50
```

> [!NOTE]
> `aptgram.service` est un service `oneshot`.
>
> Le service exécute la vérification APTGRAM, puis se termine.
>
> Il ne reste donc pas en permanence `active (running)` après une vérification réussie. C'est normal.

---

## Désinstallation

APTGRAM installe automatiquement son propre programme de désinstallation.

Lancez la désinstallation complète avec :

```bash
sudo aptgram-uninstall
```

APTGRAM demande une confirmation avant la désinstallation.

Exemple :

```text
Désinstallation d'APTGRAM
==============================

Souhaitez-vous supprimer complètement APTGRAM ? [o/N]
```

Confirmez la désinstallation avec :

```text
o
```

Le programme de désinstallation :

- arrête le timer APTGRAM
- désactive le timer APTGRAM
- arrête le service APTGRAM
- supprime les unités `systemd`
- supprime les fichiers du programme APTGRAM
- supprime les bibliothèques APTGRAM
- supprime les fichiers de langue
- supprime la configuration APTGRAM
- supprime les identifiants Telegram enregistrés
- supprime le programme de désinstallation APTGRAM

Après une désinstallation réussie, le message suivant s'affiche :

```text
APTGRAM a été complètement supprimé.
```

APTGRAM ne laisse ensuite aucun fichier de programme installé, aucun fichier de configuration ni aucune unité `systemd` sur le système.

[← Retour au README](../README.md)
