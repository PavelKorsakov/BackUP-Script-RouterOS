# MikroTik Backup Script

**Realice copias de seguridad de dispositivos MikroTik RouterOS.**

Este script crea copias de seguridad de dispositivos que ejecutan RouterOS, de forma manual o automática mediante un programador de tareas *(que se configura por separado)*.
El archivo `mikrotik-backup.sh` es un script autocontenido, aunque algunas características pueden configurarse a través de `option.cfg`.

<br>

## Características del script

| Característica | Cómo funciona |
|---|---|
| Modo de dispositivo único | Crea una copia de seguridad de un dispositivo usando opciones de la CLI |
| Procesamiento por lotes | Procesa en secuencia los dispositivos incluidos en DeviceList; puede importar la lista de Oxidized |
| Formatos de copia de seguridad | Crea archivos `.rsc`, `.backup` o ambos formatos en secuencia |
| Modos de copia de seguridad | Admite exportaciones `compact`, `terse` y `verbose`, además del cifrado de copias de seguridad binarias |
| Copias de seguridad incrementales | Puede guardar copias de seguridad solo cuando se detecta un cambio |
| Archivado mensual | Puede archivar copias de seguridad y registros antiguos al llegar a una fecha de corte del calendario |
| Registro | Registra las etapas generales en `main.log` y las operaciones de cada dispositivo en `devicename.log` |
| Menú de configuración | Ofrece un menú interactivo para facilitar la configuración y el uso |
| Localización | Incluye ruso e inglés y admite archivos externos de localización |
| Almacenamiento de copias de seguridad | Puede utilizar cualquier directorio de copias de seguridad, incluido un NAS |
| Uso de NAS | Comprueba que el almacenamiento está disponible antes de crear una copia de seguridad |

<br>

## Requisitos del sistema y puesta en marcha

**Obligatorio:**
GNU Bash 4.4 o posterior y las siguientes utilidades instaladas: **SSH**, **SCP** y **SSHPass**.
**zip** solo es necesario para el archivado mensual. Todas las utilidades requeridas y sus comandos de instalación se enumeran en [Dependencias](es/INSTALL.md#dependencias).
*(N.B. Si falta una utilidad requerida, el script termina con un error. Este es el comportamiento esperado.)*

**Opcional:**
**autofs**, **davfs2**, **rclone** y otras herramientas para montar almacenamiento externo.

**Instalación:**
Ver [Instalación](es/INSTALL.md) para instrucciones de descarga y configuración.

Ejecute los siguientes comandos en el directorio que contiene los archivos descargados:

El bloque de comandos siguiente supone archivos obtenidos de un GitHub Release. Una copia Git del código fuente no incluye el `SHA256SUMS` generado; para una copia del código fuente, empiece con `chmod 700 mikrotik-backup.sh` y continúe con las comprobaciones de versión y ayuda.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Si falla la verificación de la suma de comprobación, **no ejecute el archivo!!!**

<br>

## Formas de ejecutar el script

**Ejecute el script sin opciones adicionales** *(cuando `option.cfg` no existe o no contiene ajustes válidos)*
Si no hay un archivo `option.cfg` junto al script, o si está vacío, solo contiene comentarios o únicamente parámetros desconocidos o no válidos, se abre el Editor de configuración para que pueda crear o editar `option.cfg`.

**Ejecute el script sin opciones adicionales** *(cuando existan archivos `option.cfg` y `devicelist.cfg` válidos)*
Si ya existen configuraciones utilizables, el script comienza el procesamiento por lotes.

**Ejecute el script con una opción:**

| Tarea | Comando |
|---|---|
| Abrir el menú interactivo | `./mikrotik-backup.sh -i` |
| Abrir BackUP Master | `./mikrotik-backup.sh -b` |
| Crear o editar `option.cfg` | `./mikrotik-backup.sh -e` |
| Mostrar la ayuda completa de la CLI | `./mikrotik-backup.sh -h` |
| Ejecutar una copia de seguridad de un solo dispositivo | Proporcionar los tres parámetros completos de la CLI: dirección del dispositivo, usuario y contraseña |

La opción más importante aquí es `-i`, que abre el menú interactivo. Desde allí se puede:

- usar BackUP Master para introducir los parámetros de un dispositivo, crear sus copias de seguridad y crear o ampliar `devicelist.cfg` con los parámetros seleccionados;
- usar el Editor de configuración para crear o editar `option.cfg`;
- consultar la ayuda de la CLI;
- leer una guía breve de las características del script.

Para consultar la referencia completa de la CLI, incluidas las formas exactas `-a=...`, `-u=...` y `-p=...`, vea la [referencia de la línea de comandos](es/CLI.md).

<br>

## ¿Dónde están los resultados, o «dónde están mis copias de seguridad???»

De forma predeterminada, las copias de seguridad de los dispositivos se almacenan en el directorio `backups` situado junto al script. Si el directorio no existe, el script lo crea.
*(N.B. La ruta relativa `backups` se resuelve desde el directorio del script, no desde el directorio de trabajo actual!)*

En una ejecución para un solo dispositivo no se crea un subdirectorio específico para él:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

En el modo por lotes, cada dispositivo tiene su propio directorio:

```text
backups/
├── main.log
└── Router-A/
    ├── Router-A_YYYY-MM-DD_HH-MM.rsc
    ├── Router-A_YYYY-MM-DD_HH-MM.backup
    ├── Router-A.log
    └── archive/
        └── DD.MM.YYYY.zip
```

Estas estructuras son ejemplos; no garantizan que todos los archivos existan después de cada ejecución.
Se crea un registro cuando se escribe su primera entrada aplicable.
La opción `MainLogPath` en `option.cfg` puede mover `main.log` a `/var/log/` o cualquier otro directorio adecuado.
Consulte [Configuración](es/OPTIONS.md) para obtener detalles sobre los directorios de copias de seguridad, archivado y registros.

<br>

## Archivado mensual

Esta función está deshabilitada de forma predeterminada. Si el script se ejecuta según una programación, establezca `MonthlyArchive=true|1...28` en `option.cfg` para seleccionar el día del archivado mensual.

Ese día, una ejecución por lotes cambia su orden de trabajo: primero archiva todos los datos admisibles acumulados en el directorio de copias de seguridad y después crea las copias correspondientes a la fecha actual.

El archivo ZIP recibe el nombre del día natural anterior. Por ejemplo, una ejecución el 1 de octubre crea `30.09.YYYY.zip`.

*(N.B. Si el script NO se ejecuta a diario, debe crear una tarea programada independiente para la fecha requerida. No hace falta otra tarea si el script se ejecuta a diario o con mayor frecuencia.)*

Un intento mensual omitido, sea cual sea el motivo, no se recupera mediante ejecuciones diarias posteriores. No se realiza ninguna ejecución adicional del archivado más tarde ese mismo día ni durante el resto del mes.
El siguiente intento solo tiene lugar en la próxima fecha mensual programada y reúne en un único archivo ZIP todos los datos antiguos admisibles que se hayan acumulado, aunque el periodo pendiente abarque varios meses. `main.log` no se archiva.

Consulte [Archivado mensual](es/BACKUPS.md#monthly-archive) para conocer las reglas completas, los ejemplos y el comportamiento en caso de fallo.

<br>

## Documentación detallada

| Asunto | Página |
|---|---|
| Requisitos, dependencias y colocación de archivos | [Instalación](es/INSTALL.md) |
| Parámetros y selección de modos | [CLI](es/CLI.md) |
| Valores predeterminados y `option.cfg` | [Configuración](es/OPTIONS.md) |
| DeviceList, nombres y Oxidized | [Dispositivos](es/DEVICES.md) |
| Formatos, comparación, almacenamiento y archivos ZIP | [Copias de seguridad](es/BACKUPS.md) |
| Niveles de registro, rutas y mensajes | [Registro](es/LOGGING.md) |
| Menú, editor y BackUP Master | [Interfaz interactiva](es/INTERACTIVE.md) |
| Selección de idioma y archivos `.lang` | [Localización](es/LOCALIZATION.md) |
| Credenciales, SSH y permisos de acceso | [Seguridad](es/SECURITY.md) |
| Diagnóstico por síntoma o código de resultado | [Solución de problemas](es/TROUBLESHOOTING.md) |
| Verificación de versiones y actualizaciones | [Versiones](es/RELEASES.md) |
| Historial y planes de desarrollo | [Roadmap](es/ROADMAP.md) |

<br>

## Alcance y limitaciones

El script crea copias de seguridad, pero no restaura la configuración de un router.
La versión actual no envía notificaciones por correo electrónico ni por servicios de mensajería, y tampoco elimina archivos ZIP antiguos en función de su antigüedad.
El administrador es responsable de los procedimientos de restauración, retención externa y seguimiento de resultados.

El perfil SSH utiliza la autenticación de contraseña y deshabilita la verificación de la clave del host.
Cifrar un archivo `.backup` no cifra los archivos `.rsc`, los archivos de configuración ni los archivos ZIP.
Lea el [modelo de seguridad](es/SECURITY.md) antes de usarlo en producción.

<br>

## Documentación en otros idiomas

[English](../README.md).  
[Русский](README_RU.md).  
[Latviešu](README_LV.md).  
[Українська](README_UK.md).  
[Deutsch](README_DE.md).  
[Bahasa Indonesia](README_ID.md).  
[Português (Brasil)](README_PT-BR.md).  
[Tiếng Việt](README_VI.md).  
[Español](README_ES.md).  
[Polski](README_PL.md).  
[বাংলা](README_BN.md).

## Contactar con el autor

Envíe sugerencias de funciones, informes de errores y preguntas sobre el script a [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev),
o póngase en contacto con el autor por Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
