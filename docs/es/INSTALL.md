# Instalación

[Índice](../README_ES.md)

## Requisitos del host

El script requiere Linux con GNU Bash **4.4 o posterior** y las utilidades estándar de GNU para trabajar con archivos.
El propio script no requiere compilación, Python, contenedores ni bases de datos.
Sin embargo, necesita las utilidades enumeradas en [Dependencias](#dependencias).

El tratamiento de los nombres de dispositivo requiere una configuración regional **`C.UTF-8`** funcional para contar caracteres multibyte, reconocer letras y convertir entre mayúsculas y minúsculas.
El script comprueba estas capacidades antes de trabajar con los dispositivos. Se trata de un requisito del sistema, no de un programa independiente llamado `C.UTF-8`.

Naturalmente, el host debe tener acceso de red al servicio SSH de RouterOS y permiso de escritura en el almacenamiento seleccionado.

**¡Muy recomendable!!!**
El script se conecta a los dispositivos RouterOS mediante SSH con autenticación por contraseña, no mediante claves.
*(Consulte [SECURITY.md](SECURITY.md) para conocer la política de transporte exacta.)*
Por tanto, conviene crear un usuario dedicado en el dispositivo y restringir su inicio de sesión a la dirección IP del host que ejecuta el script.

<br />

## Dependencias

### Necesario para copias de seguridad

**Todas** las utilidades siguientes son necesarias para crear copias de seguridad:

| Utilidades | Propósito |
|---|---|
| `ssh`, `scp`, `sshpass` | Conectarse a RouterOS, ejecutar comandos y obtener archivos |
| GNU `timeout` y `sleep` | Limitar la duración de las operaciones e introducir pausas |
| `sha256sum` | Calcular sumas de comprobación |
| `realpath` | Resolver rutas absolutas |
| `flock` | Bloqueo para evitar ejecuciones simultáneas conflictivas |

**Si falta una utilidad necesaria, el script informa de dependencias insatisfechas
y detiene el intento de copia de seguridad.
El código de error de dependencia es `30`. Este es el comportamiento esperado.**

La lista es la misma para las copias de un solo dispositivo y las copias por lotes, con independencia de que
el script cree `.rsc`, `.backup` o ambos formatos.

No basta con que existan comandos con esos nombres. La versión instalada de OpenSSH debe
admitir las opciones que utiliza el script, incluido el modo SCP heredado que se selecciona mediante `scp -O`.
GNU `timeout` debe admitir `--signal` y `--kill-after`.
Estas capacidades se verifican localmente, sin conectarse al router.

<br />

### Requisitos de funciones específicas

Estas herramientas no forman parte de la lista general de requisitos. Son necesarias
cuando se utiliza la función correspondiente.

| Función | Requisito | Qué ocurre si falta |
|---|---|---|
| Modo por lotes con `UseNetFolder=true` | `findmnt` | La copia de seguridad no comienza en este modo; error de dependencia `30` |
| Ejecución en la que corresponde el archivado mensual | Info-ZIP `zip`, `unzip`, GNU `mv` | La ejecución se detiene durante la comprobación de dependencias, antes de crear ninguna copia; error `30` |
| Menú interactivo, Editor de configuración y BackUP Master | `stty` y un terminal conectado a la entrada y salida estándar | La pantalla interactiva no se abre; error de terminal `31` |
| **3. Copiar el comando de consola** en BackUP Master | GNU `base64` compatible con `--wrap=0` | No se puede copiar el comando; error `30` |

Por ejemplo, la ausencia de `zip` no impide una ejecución normal de copia de seguridad cuando no corresponde realizar el archivado mensual.
La ausencia de `base64` no impide que se creen copias de seguridad.
*(N.B. Se requiere cuando elige **3. Copiar el comando de consola**.)*

La comprobación general de dependencias se ejecuta antes de una copia de seguridad, no cada vez que se inicia el programa.
Por ello, la ayuda, la información de versión o el menú pueden estar disponibles aunque no estén instaladas las utilidades de copia de seguridad.

<br />

### Entorno base de Linux

El script también presupone que están disponibles los comandos habituales del sistema para trabajar con archivos
y directorios, incluidos `date`, `stat`, `mkdir`, `cp`, `ln` y `rm`.

Forman parte del entorno básico del sistema operativo.
La comprobación previa no incluye todos los comandos externos utilizados por el
script. Si falta un comando de sistema base, la operación correspondiente puede fallar
en lugar de producir un mensaje de dependencia no satisfecha.

<br />

### Instalar los paquetes necesarios en Debian/Ubuntu

Este ejemplo instala las herramientas necesarias y las herramientas opcionales enumeradas anteriormente:
*(N.B. Aquí y abajo, se supone que el usuario tiene privilegios de administrador.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Obtener los archivos del script

El método principal de instalación de la versión 2.3.1 es el asset completo de GitHub Release `mikrotik-backup-2.3.1.zip`. Se extrae directamente en el directorio de instalación, sin un directorio contenedor adicional.
*(N.B. En los ejemplos que colocan archivos bajo `/opt`, ejecute los comandos con permiso para crear ese directorio y escribir en él.)*

### Opción 1: Paquete completo de la versión

Descargue `mikrotik-backup-2.3.1.zip` del GitHub Release de MikroTik Backup Script 2.3.1 y ejecute:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Después de la extracción, la estructura lista para usar es:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Si la verificación de la suma de comprobación falla, no ejecute el script hasta encontrar la causa.

<br />

### Opción 2: Instalación autónoma mínima

Descargue los assets `mikrotik-backup.sh` y `SHA256SUMS` de la misma versión en un directorio protegido, verifíquelos y haga ejecutable el script:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Descargue los dos assets del Release en este directorio.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Para un idioma externo de runtime, utilice el paquete completo u obtenga el archivo `.lang` correspondiente del código fuente etiquetado de la misma versión.

<br />

### Opción avanzada: Git o archivo del código fuente

Un clon Git o el archivo **Code → Download ZIP** de este repositorio también contiene el árbol fuente completo del producto. La estructura útil en la raíz es:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` es un asset del Release y puede no estar presente en una copia del código fuente. Para una instalación normal se sigue recomendando el paquete versionado del Release, porque incluye el archivo de suma de comprobación y corresponde exactamente a la versión publicada.

<br />

## Archivos junto al script

Después de extraer el paquete completo del Release, el directorio seleccionado contiene el script y los archivos que lo acompañan:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Archivo o directorio | Propósito |
|---|---|
| mikrotik-backup.sh | El script de copia de seguridad en sí |
| SHA256SUMS | Sumas de comprobación usadas para verificar los archivos descargados |
| README.md | Descripción del producto y enlaces a documentación detallada |
| lang/ | Archivos de localización. Copie el archivo de idioma requerido desde este directorio al directorio del script. |
| docs/ | Documentación detallada de instalación, configuración y uso |

Para la operación real, solo se requiere `mikrotik-backup.sh`.
Para cambiar la configuración, cree **option.cfg** y colóquela junto al script.
Si prevé consultar y crear copias de seguridad de varios dispositivos en secuencia, cree también **devicelist.cfg** junto al script.
Necesitará un archivo de localización llamado `<xx>.lang` si desea que los menús y las entradas de registro aparezcan en su idioma. Colóquelo en el mismo directorio que `mikrotik-backup.sh`.
Ruso e inglés no requieren archivos de localización separados porque ambos están integrados en el script.

**En modo interactivo, el script puede crear y guardar:**
La lista de dispositivos —**devicelist.cfg**— mediante BackUP Master.
El archivo de configuración —**option.cfg**— mediante el Editor de configuración.
También puede prepararlos usted mismo:
*El formato TSV de la lista de dispositivos se describe detalladamente en [DEVICES.md](DEVICES.md).*
*El formato `Key=value` del archivo de configuración se describe detalladamente en [OPTIONS.md](OPTIONS.md).*

<br />

## Preparación de almacenamiento y registros

Con la configuración predeterminada, el script crea un directorio `./backups` junto al propio script y almacena allí las copias de seguridad de los dispositivos.
La diferencia entre los modos es que una ejecución para un solo dispositivo guarda los archivos directamente en `./backups`, mientras que el modo por lotes crea dentro de `./backups` un subdirectorio con el nombre del dispositivo y almacena allí sus copias.

El script crea los directorios de almacenamiento requeridos con los permisos apropiados.
*(No cambia automáticamente el propietario ni el modo de acceso de los directorios existentes que haya creado el administrador.)*

De forma predeterminada, el registro principal del script, `main.log`, se almacena en `./backups`.
En el modo por lotes, el registro de cada dispositivo se almacena en su subdirectorio.

También debe saber que, cuando el directorio de copias de seguridad se encuentra en un almacenamiento de red,
el script puede comprobar la disponibilidad de ese directorio durante el procesamiento por lotes. Esta opción está desactivada de forma predeterminada y debe configurarse antes de usarla.
*(No importa cómo esté montado el directorio.)*

Todas estas opciones pueden cambiarse estableciendo los parámetros necesarios en `option.cfg`.
Consulte [Configuración](OPTIONS.md) para conocer las instrucciones y la sintaxis de los parámetros.

<br />

## Ejecutar el script automáticamente

Antes de activar una programación, prepare la configuración y la lista de dispositivos.
De lo contrario, una ejecución automática no podrá realizar una copia de seguridad por lotes.

No es obligatorio crear un usuario independiente para ejecutar el script, pero realizar estas operaciones como **root** se considera una mala práctica. El siguiente ejemplo crea un usuario dedicado.

Cree el usuario **bsmt** *(puede elegir otro nombre; sustituya **bsmt** en los ejemplos)* y concédale únicamente los permisos necesarios:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Si el script ya ha sido ejecutado como root**

*(N.B. Si previamente ejecutó el script como **root**, los directorios, copias de seguridad,
y los registros que creó podrían no ser accesibles para **bsmt**.
Transfiera el almacenamiento existente a ese usuario antes de habilitar la programación.)*

Este ejemplo utiliza el directorio local `/opt/mikrotik-backup/backups`.
El siguiente comando cambia el propietario y grupo del directorio y todo lo que hay en él:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(N.B. Especifique el directorio de copia de seguridad de este script, no un directorio compartido que también contiene datos de otros programas.
Si el almacenamiento o el registro principal se encuentran en otro lugar, configure por separado el acceso a cada uno según los permisos y ajustes del almacenamiento seleccionado, siguiendo el mismo patrón.)*

Este ejemplo abre el Editor de configuración como **bsmt** después de conceder al usuario acceso al directorio y a los archivos del script:
*(N.B. Ejecute el comando como root o como usuario autorizado a hacerlo a través de sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Crear una programación para el script**

El siguiente ejemplo crea una programación con systemd,
pero puede utilizar crontab o cualquier otro método que prefiera.

Crearemos un servicio que ejecute el script con el usuario dedicado y un temporizador que lo inicie según la programación.
*(El ejemplo se ejecuta todos los días a la 1 de la madrugada, pero usted puede elegir el horario.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` impide una ejecución de recuperación tras un periodo en el que el temporizador estuvo apagado.
`Restart=no` no programa reinicios automáticos del servicio después de un error.*
