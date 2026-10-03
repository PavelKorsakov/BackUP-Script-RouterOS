# Copias de seguridad y archivos ZIP

[Índice](../README_ES.md)

## Formatos de copia de seguridad

El script puede guardar la configuración del dispositivo como texto, crear una copia de seguridad binaria o obtener ambos formatos.
El parámetro `backup_type` en `option.cfg` selecciona el formato:

| Valor | Qué se guarda |
|---|---|
| `configuration` | Configuración de RouterOS en un archivo `.rsc` |
| `binary` | Copia de seguridad binaria en un archivo `.backup` |
| `both` | Ambos formatos: `.rsc` primero, luego `.backup` |

El valor predeterminado es `both`. Puede cambiarlo en el archivo de opciones, en el Editor de configuración, en BackUP Master o mediante `--backup-type`.

### Exportación de configuración de texto: .rsc

El parámetro `export_format` selecciona el formato de exportación. Los valores válidos son `compact`, `terse` y `verbose`; el valor predeterminado es `compact`.

El parámetro `show_sensitive` determina si la exportación incluye datos sensibles, incluidas las contraseñas. Está activado de forma predeterminada.
Para desactivarlo, añádalo a `option.cfg`:

```ini
show_sensitive=false
```

### Copia de seguridad binaria: .backup

Puede cifrar una copia de seguridad binaria. Establezca la contraseña requerida en `encrypt`:

```ini
encrypt=MySuperPassword
```

Con un valor `encrypt=` vacío, el archivo `.backup` se guarda sin cifrar. Este es el comportamiento predeterminado.

*(N.B. El cifrado AES-SHA256 se aplica únicamente a `.backup`. No cifra las configuraciones de texto, los registros ni los archivos ZIP.)*

De forma predeterminada, el script borra la caché DNS y el historial de consola de RouterOS antes de crear una copia de seguridad binaria. Si no necesita estas operaciones, desactive los parámetros correspondientes:

```ini
clear_dns_cache=false
clear_console_history=false
```

Estas operaciones de limpieza no se realizan cuando solo se obtiene una configuración de texto.

<br />

## Nombres de archivos y ubicaciones

De forma predeterminada, las copias de seguridad se almacenan en el directorio `backups` situado junto al script. Para utilizar otro directorio, defina `BackupRoot` en el archivo de opciones.

En una ejecución para un solo dispositivo, los archivos se guardan directamente en ese directorio:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

En el modo por lotes, cada dispositivo tiene su propio subdirectorio:

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

El nombre de un archivo de copia de seguridad contiene el nombre del dispositivo y la fecha y hora del reloj del host que ejecuta el script. Los dos formatos creados por una misma operación utilizan la misma marca de tiempo.
La construcción del nombre del dispositivo se describe en [DEVICES.md](DEVICES.md#device-names).

**¡Atención!!!**
Si crea dos copias del mismo dispositivo en el mismo directorio durante un mismo minuto, los nombres de archivo coincidirán. El archivo existente se sustituirá; no se creará una versión independiente para la segunda ejecución.

También puede utilizar un directorio de red como almacenamiento. En el modo por lotes, establezca `UseNetFolder=true` para comprobarlo. La preparación del directorio se describe en [INSTALL.md](INSTALL.md), y la configuración de la ruta en [OPTIONS.md](OPTIONS.md#network-storage).

[LOGGING.md](LOGGING.md) explica la ubicación y el contenido de los registros en detalle.

<br />

## Copias de seguridad incrementales

Esta función evita conservar copias de seguridad duplicadas cuando no se detecta ningún cambio. El parámetro `UseIncremental` controla este comportamiento:

| Valor | Cómo se conservan las copias de seguridad |
|---|---|
| `true` (valor predeterminado) | Si la nueva copia se identifica como duplicada, se elimina y se conserva la copia anterior |
| `false` | Cada nueva copia de seguridad válida se conserva sin compararla con la anterior |

Cuando se detecta un cambio o no existe copia de seguridad previa, se mantiene el nuevo archivo. Si la comparación no puede completarse, el archivo también se mantiene, pero el script emite una advertencia.

**¡Aquí está la clave!!!**
El método de comparación depende del formato:

| Formato | Qué se compara |
|---|---|
| `.rsc` | Contenido del archivo. Se omiten la fecha y la hora del encabezado estándar de RouterOS |
| `.backup` | Únicamente el tamaño del archivo en bytes |

Por lo tanto, dos archivos binarios del mismo tamaño se tratan como duplicados incluso cuando su contenido difiere. Tenga esto en cuenta al elegir la configuración de retención.

El script compara el archivo nuevo con la copia de seguridad más reciente del mismo dispositivo y formato en el directorio correspondiente. Las copias ya incluidas en un ZIP no participan en la comparación.

El script conserva archivos `.rsc` y `.backup` normales, no archivos de diferencias independientes. Deshabilitar `UseIncremental` no deshabilita la obtención y verificación de las copias, el registro ni el archivado mensual.

<br />

<a id="monthly-archive"></a>
## Archivado mensual

Esta función está deshabilitada de forma predeterminada. Configure `MonthlyArchive` en `option.cfg` para elegir el día en que se archivarán las copias de seguridad y los registros acumulados:

| Valor | Comportamiento |
|---|---|
| `false` (valor predeterminado) | El archivado está desactivado |
| `true` o `1` | El archivado se ejecuta el primer día del mes |
| `2` a `28` | El archivado se ejecuta el día indicado del mes |

La hora de ejecución dentro del día seleccionado no importa. Configure la programación por separado, como se describe en [INSTALL.md](INSTALL.md#ejecutar-el-script-automáticamente).

### Qué se incluye en el archivo ZIP

En el modo por lotes, el orden de trabajo cambia ese día: el script primero reúne en un ZIP los archivos acumulados del dispositivo y solo después crea nuevas copias de seguridad. Las copias creadas durante la ejecución actual permanecen fuera del ZIP.

El ZIP incluye los archivos normales situados directamente en el directorio del dispositivo, incluido el registro acumulativo completo de ese dispositivo. No se limita a `.rsc` y `.backup`: también pueden archivarse otros archivos normales que se coloquen en el directorio.

Los subdirectorios, los enlaces simbólicos, los archivos auxiliares de la ejecución actual y los archivos ZIP creados anteriormente por el script no se vuelven a empaquetar. **El registro principal, `main.log`, no se archiva.**

Una vez verificado y guardado el ZIP completo, se eliminan del directorio del dispositivo los archivos de origen incluidos en él. Si no hay nada que archivar, no se crea un ZIP vacío.

### Nombre y ubicación del archivo ZIP

El ZIP recibe como nombre el día natural anterior en formato `DD.MM.YYYY.zip`. Por ejemplo, una ejecución el 1 de octubre de 2026 crea `30.09.2026.zip`; una ejecución el 15 de octubre crea `14.10.2026.zip`.

| Modo | Ubicación del archivo ZIP |
|---|---|
| Por lotes | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Dispositivo único mediante la CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

Otra ejecución en la misma fecha actualiza el archivo ZIP de igual nombre.

### Modo de un dispositivo único y BackUP Master

En una ejecución de un solo dispositivo mediante la CLI, el orden se invierte: primero se crea la copia de seguridad y después se archiva. Por tanto, la copia creada en la ejecución actual también puede entrar en el ZIP.

En este modo se archivan los archivos `.rsc`, `.backup` y `.log` situados directamente en `BackupRoot`, excepto `main.log`. Si los resultados de ejecuciones individuales de varios dispositivos comparten un directorio, sus archivos se incluyen en el mismo ZIP.

El archivado mensual no se ejecuta cuando se utiliza BackUP Master.

### Si se pierde una ejecución

Si el script no se ejecuta el día seleccionado, el intento mensual omitido no se recupera más adelante. El siguiente intento solo tiene lugar el día programado del mes siguiente.

En el siguiente intento satisfactorio, todos los archivos admisibles acumulados se incluyen en un único ZIP, aunque el periodo pendiente abarque dos, tres o más meses. No se crean archivos ZIP independientes para los meses omitidos.

### Si falla el archivado

Los archivos de origen no se eliminan hasta que se haya guardado un ZIP verificado correctamente. Tampoco se sustituye por uno nuevo un ZIP existente que esté dañado.

Si el ZIP ya se ha guardado, pero algunos archivos de origen no pueden eliminarse, tanto el ZIP completo como los archivos que no pudieron borrarse permanecen en su sitio. Consulte el registro para averiguar la causa del error.

*(N.B. El archivo ZIP se genera en el directorio local `/tmp` incluso cuando las copias de seguridad se almacenan en un NAS. Por tanto, también se necesita espacio libre fuera del almacenamiento.)*

<br />

## Si falla la copia de seguridad

Después de un intento infructuoso de recuperar un archivo, el script intenta una vez más después de 2 segundos. Los reintentos para `.rsc` y `.backup` se realizan por separado.

Un error normal al obtener un formato no cancela el intento de obtener el otro. Si un dispositivo no está disponible, el script continúa con los dispositivos restantes. Si se pierde el almacenamiento compartido, el procesamiento por lotes se detiene.

Los mensajes de error y los códigos de resultados se describen en [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Retención y restauración

Los archivos ZIP antiguos no se eliminan por antigüedad ni por cantidad. Usted decide el periodo de retención y la política de rotación externa.

El script crea copias de seguridad, pero no restaura RouterOS. Pruebe la restauración por separado en un dispositivo adecuado.

*(N.B. Las copias de seguridad y los archivos ZIP pueden contener contraseñas y otros datos confidenciales. Restrinja el acceso al almacenamiento como se describe en [SECURITY.md](SECURITY.md).)*
