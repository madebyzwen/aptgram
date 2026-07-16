# APTGRAM – Instalación en español

[← Volver al README](../README.md)

Esta guía explica paso a paso cómo configurar el bot de Telegram, el canal de Telegram e instalar APTGRAM.

## Instalación

APTGRAM está diseñado para sistemas Linux basados en Debian que utilizan `systemd` y el gestor de paquetes APT.

Por ejemplo:

- Debian
- Ubuntu
- sistemas de servidor basados en Debian
- sistemas NAS UGREEN compatibles con UGOS Pro

También necesitas:

- un bot de Telegram
- un canal de Telegram para las notificaciones de APTGRAM
- el **Telegram Bot Token**
- el **Telegram Chat ID** numérico del canal

¿Nunca has creado un bot de Telegram?

No hay problema. Los siguientes pasos te guiarán por toda la configuración.

---

### 1. Crear un bot de Telegram

Abre Telegram y busca:

```text
@BotFather
```

Asegúrate de utilizar el BotFather oficial de Telegram.

Abre el chat y envía:

```text
/newbot
```

BotFather te guiará ahora durante la creación del bot.

#### Elegir el nombre del bot

Primero, BotFather solicita un nombre para el bot.

Este nombre se mostrará posteriormente en Telegram.

Ejemplo:

```text
APTGRAM Server
```

Puedes elegir el nombre libremente.

#### Elegir el nombre de usuario del bot

A continuación, el bot necesita un nombre de usuario único.

El nombre de usuario debe terminar en `bot`.

Ejemplo:

```text
my_aptgram_bot
```

Si el nombre de usuario ya está ocupado, debes elegir otro.

Después de crear correctamente el bot, BotFather muestra el **Telegram Bot Token**.

Un bot token tiene un aspecto similar a este:

```text
1234567890:AAExampleTokenDoNotUseThisValue
```

Copia el token completo.

Lo necesitarás más adelante durante la instalación de APTGRAM.

> [!IMPORTANT]
> El Telegram Bot Token es un dato secreto y debe tratarse como una contraseña.
>
> Nunca publiques el token en un issue de GitHub, una captura de pantalla, un foro, un registro del terminal o un chat.
>
> Si el token se publica accidentalmente, revócalo inmediatamente mediante `@BotFather` y crea uno nuevo.

![BotFather después de crear correctamente el bot de Telegram](images/telegram-botfather-token.png)


---

### 2. Crear un canal de Telegram

Crea un canal nuevo en Telegram.

Puedes elegir libremente el nombre del canal.

Ejemplo:

```text
APTGRAM Updates
```

El canal puede ser público o privado.

APTGRAM solo necesita poder publicar mensajes en este canal mediante el bot creado anteriormente.

---

### 3. Añadir el bot de Telegram como administrador

Abre la configuración de tu canal de Telegram.

Busca:

```text
Administradores
```

o, si la interfaz de Telegram está en inglés:

```text
Administrators
```

Añade como administrador el bot que creaste anteriormente.

Búscalo por su nombre de usuario.

Ejemplo:

```text
@my_aptgram_bot
```

El bot necesita como mínimo permiso para publicar mensajes en el canal.

APTGRAM no necesita ningún otro permiso de administrador.

![Bot de APTGRAM como administrador del canal de Telegram](images/telegram-channel-admin.png)


---

### 4. Obtener el Telegram Chat ID del canal

APTGRAM necesita el Chat ID numérico del canal de Telegram.

Un ID de canal tiene, por ejemplo, este aspecto:

```text
-1001234567890
```

La forma más sencilla de obtener el ID del canal es mediante **Telegram Web**. Para ello no necesitas un terminal ni el bot token.

1. Abre en el navegador:

   ```text
   https://web.telegram.org
   ```

2. Inicia sesión con tu cuenta de Telegram.

3. Abre en la barra lateral izquierda el canal de Telegram que quieres utilizar para APTGRAM.

4. Observa la dirección que aparece en la barra de direcciones del navegador.

La dirección tiene un aspecto similar a este:

```text
https://web.telegram.org/a/#-1001234567890
```

El ID completo del canal aparece después del `#`:

```text
-1001234567890
```

Copia el número completo, incluido el signo menos.

Necesitarás este ID del canal durante la instalación de APTGRAM.

![Telegram Chat ID del canal en Telegram Web](images/telegram-chat-id.png)


#### ¿No aparece el ID del canal?

Comprueba los siguientes puntos:

1. Has abierto el canal correcto en Telegram Web.
2. No estás en una conversación privada con el bot.
3. No has abierto el grupo de debate vinculado al canal.
4. Estás utilizando la dirección completa de la barra de direcciones del navegador.
5. El ID del canal copiado comienza por `-100`.

---

### 5. Descargar APTGRAM

Abre un terminal en el sistema donde se instalará APTGRAM.

Si `git` todavía no está instalado, puedes instalarlo en sistemas basados en Debian con:

```bash
sudo apt update
sudo apt install git
```

A continuación, clona el repositorio de APTGRAM desde GitHub:

```bash
git clone https://github.com/madebyzwen/aptgram.git
```

Cambia al directorio del proyecto descargado:

```bash
cd aptgram
```

---

### 6. Instalar APTGRAM

Inicia el instalador con:

```bash
bash install.sh
```

No debes iniciar el instalador con `sudo bash install.sh`.

APTGRAM solicitará por sí mismo permisos de `sudo` en cuanto sean necesarios para la instalación.

Al iniciarse, APTGRAM detecta automáticamente el idioma del sistema.

Ejemplo:

```text
Instalación de APTGRAM
==============================

Idioma detectado: Español

¿Quieres cambiar el idioma? [s/N]
```

Pulsa `Enter` para utilizar el idioma detectado.

También puedes cambiar el idioma durante la instalación.

---

### 7. Introducir el Telegram Bot Token

APTGRAM solicita el Telegram Bot Token:

```text
Telegram Bot Token:
```

Pega el token completo que recibiste de `@BotFather`.

APTGRAM comprueba el token directamente a través de Telegram.

Si el token es válido, aparece:

```text
Comprobando Bot Token...
Bot Token comprobado correctamente.
```

Si el token no es válido, APTGRAM solicita que lo introduzcas de nuevo.

---

### 8. Introducir el Telegram Chat ID

A continuación, APTGRAM solicita el Telegram Chat ID:

```text
Telegram Chat ID:
```

Pega el ID del canal que obtuviste anteriormente.

Ejemplo:

```text
-1001234567890
```

El signo menos del principio forma parte del Chat ID y no debe eliminarse.

APTGRAM comprueba automáticamente la conexión con Telegram.

Si la conexión se realiza correctamente, aparece:

```text
Comprobando la conexión con Telegram...
Conexión con Telegram correcta.
```

Abre ahora tu canal de Telegram.

Debería haber llegado un mensaje de prueba de APTGRAM.

![Mensaje de prueba correcto de APTGRAM en el canal de Telegram](images/telegram-test-message.png)


Cuando hayas recibido el mensaje de prueba, la configuración de Telegram habrá finalizado correctamente.

---

### 9. Establecer la hora de comprobación diaria

APTGRAM solicita ahora la hora de la comprobación diaria de actualizaciones.

De forma predeterminada se propone `20:00`:

```text
Hora de comprobación diaria [20:00]:
```

Pulsa `Enter` para aceptar la hora predeterminada.

También puedes introducir otra hora en formato de 24 horas.

Ejemplo:

```text
06:30
```

APTGRAM ejecutará la comprobación automática de actualizaciones cada día a esa hora.

---

### 10. Revisar la configuración

Antes de la instalación propiamente dicha, APTGRAM muestra un resumen de la configuración.

Ejemplo:

```text
Configuración
==============================

Idioma: Español
Telegram Chat ID: -1001234567890
Comprobación diaria: 20:00
Telegram Bot Token: comprobado correctamente
```

El Telegram Bot Token completo no vuelve a mostrarse en este resumen.

---

### 11. Instalación automática

APTGRAM realiza ahora automáticamente el resto de la instalación.

Durante este proceso:

- se instalan los archivos de programa de APTGRAM
- se instalan las bibliotecas de APTGRAM
- se instalan los archivos de idioma
- se guarda el idioma seleccionado
- se guarda el Telegram Chat ID
- se guarda de forma protegida el Telegram Bot Token como credencial de systemd
- se configura un servicio de `systemd`
- se configura un temporizador de `systemd`
- se activa automáticamente el temporizador
- se inicia una primera comprobación de APTGRAM

Durante la instalación aparecen los mensajes de estado correspondientes.

Ejemplo:

```text
Instalando archivos de APTGRAM...

Instalando el servicio y el temporizador de systemd...

Activando el temporizador de APTGRAM...

Iniciando la primera comprobación de APTGRAM...
```

Después de una instalación correcta aparece:

```text
APTGRAM se ha instalado correctamente.
```

---

### 12. Comprobar el primer informe de APTGRAM

Inmediatamente después de la instalación, APTGRAM inicia automáticamente una primera comprobación.

Si hay actualizaciones de paquetes disponibles, APTGRAM envía un resumen al canal de Telegram configurado.

El mensaje incluye, entre otros datos, el número de:

- actualizaciones de seguridad
- actualizaciones normales
- backports
- actualizaciones procedentes de fuentes de paquetes externas
- actualizaciones del kernel

Además, APTGRAM envía al canal de Telegram un informe detallado de actualizaciones como archivo de texto.

De este modo también se comprueba que:

- APT puede consultarse correctamente
- las actualizaciones se detectan
- las fuentes de paquetes se analizan
- Telegram está accesible
- el bot puede enviar mensajes
- los archivos adjuntos pueden transferirse a Telegram

---

### 13. Comprobar la instalación de APTGRAM

Comprueba si el temporizador de APTGRAM está activado:

```bash
systemctl is-enabled aptgram.timer
```

La salida esperada es:

```text
enabled
```

Puedes mostrar la siguiente ejecución programada con:

```bash
systemctl list-timers aptgram.timer
```

Puedes mostrar los últimos mensajes del servicio de APTGRAM con:

```bash
journalctl -u aptgram.service --no-pager -n 50
```

> [!NOTE]
> `aptgram.service` es un servicio `oneshot`.
>
> El servicio ejecuta la comprobación de APTGRAM y después finaliza.
>
> Por este motivo, después de una comprobación correcta no permanece de forma permanente como `active (running)`. Esto es normal.

---

## Desinstalación

APTGRAM instala automáticamente su propio desinstalador.

Inicia la desinstalación completa con:

```bash
sudo aptgram-uninstall
```

APTGRAM solicita confirmación antes de desinstalarse.

Ejemplo:

```text
Desinstalación de APTGRAM
==============================

¿Quieres eliminar APTGRAM completamente? [s/N]
```

Confirma la desinstalación con:

```text
s
```

El desinstalador:

- detiene el temporizador de APTGRAM
- desactiva el temporizador de APTGRAM
- detiene el servicio de APTGRAM
- elimina las unidades de `systemd`
- elimina los archivos de programa de APTGRAM
- elimina las bibliotecas de APTGRAM
- elimina los archivos de idioma
- elimina la configuración de APTGRAM
- elimina las credenciales de Telegram guardadas
- elimina el desinstalador de APTGRAM

Después de una desinstalación correcta aparece:

```text
APTGRAM se ha eliminado completamente.
```

APTGRAM no deja archivos de programa instalados, archivos de configuración ni unidades de `systemd` en el sistema.

[← Volver al README](../README.md)
