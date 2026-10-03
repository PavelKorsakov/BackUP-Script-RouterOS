# Configuración

[Índice](../README_ES.md)

## Antes de empezar

El archivo opcional `option.cfg` permite cambiar la configuración que el script usa de forma predeterminada.
Para que el script cargue los ajustes listados en este archivo durante la ejecución,
`option.cfg` debe estar junto a `mikrotik-backup.sh`, en el mismo directorio.

La estructura del archivo es muy sencilla: una lista de entradas `Key=value`. No es un script de shell.
No se expanden variables ni se ejecutan comandos.

## Cuando una configuración es utilizable para una ejecución

Una sola línea válida y reconocida basta para que la configuración sea utilizable.
No es necesario enumerar todos los ajustes: si un valor predeterminado le sirve, esa opción no tiene que aparecer en `option.cfg`.

Si el archivo está vacío o solo contiene comentarios, claves desconocidas o valores no válidos, el script no tiene nada que cargar.
En ese caso, los ajustes conservan sus valores predeterminados.

**¡Aquí está la clave!!!**
Si ejecuta el script sin argumentos en ese estado, no se inicia ninguna copia de seguridad. En su lugar, el script intenta abrir el Editor de configuración.
Lo mismo sucede cuando `option.cfg` no existe en absoluto.
Guarde los ajustes necesarios y vuelva a ejecutar el script.
*(N.B. El editor requiere un terminal. Si el script se ejecuta sin uno, por ejemplo, por un programador de tareas, sale con error `31`.
Prepare `option.cfg` antes de configurar una ejecución automática.)*

**Orden en el que se leen los parámetros opcionales:**
El script aplica las fuentes de parámetros por orden de prioridad. Si `option.cfg` no existe, utiliza los valores predeterminados integrados.
Si el archivo existe y se lee correctamente, los parámetros <mark>válidos</mark> que contiene sustituyen a los valores predeterminados correspondientes.

Y lo más importante!!! Si el mismo parámetro se proporciona mediante la CLI, prevalece el valor de la CLI.
Para una ejecución normal, ya sea de un solo dispositivo o por lotes, la prioridad es la siguiente:
**Valores integrados** → **líneas válidas de `option.cfg`** → **CLI**

*(N.B. Un archivo ausente no es el mismo que un archivo ilegible.
Si `option.cfg` existe pero el script no puede leerlo, la ejecución termina con
error de configuración `21`; no continúa con los valores predeterminados.)*

## Cómo se lee el archivo

Cada línea se divide por el primer `=`. Los nombres de las claves no distinguen entre mayúsculas y minúsculas, pero los guiones y los guiones bajos no son intercambiables.
Se ignoran las líneas en blanco y aquellas cuyo primer carácter distinto de un espacio sea `#`. Una línea desconocida o no válida no invalida las líneas correctas contiguas.
Cuando una clave aparece más de una vez, se utiliza el último valor válido.

Los espacios iniciales y finales se eliminan de los valores normales.
**Importante:** para `Login`, `Password` y `encrypt`, todo lo que aparezca después del primer `=` se conserva literalmente.
No añada comillas siguiendo la sintaxis del shell: las comillas pasarían a formar parte del valor.
No ponga un comentario después de una contraseña. Utilice una línea separada para el comentario.

Se admite un BOM al comienzo del archivo y los finales de línea CRLF.
Se permite un enlace simbólico legible a un archivo regular.
Un problema de acceso o un tipo de objeto no adecuado no se trata como un archivo vacío
y causa un error de configuración.

## Creación, edición y guardado de `option.cfg`

La forma más fácil de crear el archivo es ejecutar el script con `-e`:

```bash
./mikrotik-backup.sh -e
```

El Editor de configuración se abre y muestra las opciones principales.
Si no caben todas las líneas en la ventana del terminal, la lista se desplazará automáticamente al moverse con las teclas de flecha.
Los elementos **Guardar** y **Cancelar** se encuentran al final de la misma lista.
Recorra el menú, introduzca los ajustes que necesite → seleccione **Guardar** → y (usted es maravilloso) el archivo quedará creado.

Tenga en cuenta que, mientras trabaja en el menú interactivo, el editor cambia la configuración solo en la memoria.
Solo después de seleccionar **Guardar** se escribe el archivo *canónico* completo.

Si `option.cfg` aún no existe, el editor rellena inicialmente los campos con los valores predeterminados.
Si el archivo ya existe y se han cambiado algunos parámetros, el Editor de configuración rellena los campos con esos valores en lugar de los predeterminados.

La segunda forma de crear `option.cfg` es hacerlo manualmente. Sí: abra con sus propias manos su editor de texto favorito e introduzca los ajustes que necesite.
¿Dónde puede encontrarlos? Justo debajo:

## Ajustes y valores predeterminados

| Clave | Valor predeterminado | Valor y propósito |
|---|---|---|
| `Language` | `auto` | `auto` o dos letras ASCII, como `ru`, `en`, o `de` |
| `SshPort` | `22` | Puerto `1`–`65535`; oculto en el editor, visible en BackUP Master |
| `UseOxidized` | `false` | Importar dispositivos de Oxidized |
| `IgnoreOxiAccess` | `true` | Permitir la DeviceList anterior después de un fallo de lectura o análisis de Oxidized; solo en archivo |
| `OxidizedHome` | Vacío | Directorio que contiene `config` y `router.db` |
| `UseIdentityName` | `true` | Utilizar la identidad actual de RouterOS como nombre del dispositivo |
| `backup_type` | `both` | `configuration`, `binary`, o `both` |
| `UseIncremental` | `true` | Comparar una nueva copia verificada con la anterior; con `false`, conservar cada copia nueva sin compararla |
| `export_format` | `compact` | `compact`, `terse`, o `verbose` |
| `show_sensitive` | `true` | Incluir valores sensibles en `.rsc` |
| `encrypt` | Vacío | Contraseña utilizada para cifrar `.backup`; vacío significa no cifrado |
| `encrypt_type` | `aes-sha256` | Algoritmo fijo; solo en archivo |
| `clear_dns_cache` | `true` | Limpiar la caché DNS antes de una copia de seguridad binaria |
| `clear_console_history` | `true` | Limpiar el historial de la consola antes de una copia de seguridad binaria |
| `BackupRoot` | `backups` | Directorio raíz para almacenar las copias de seguridad |
| `UseNetFolder` | `false` | Exigir un montaje independiente en el modo por lotes |
| `MonthlyArchive` | `false` | Archivado desactivado (`false`) o día del mes del `1` al `28` |
| `LogLevel` | `2` | Nivel `0`, `1`, `2`, o `3` |
| `MainLogPath` | Vacío | Directorio para `main.log` solamente; vacío significa el `BackupRoot` actual |
| `Login` | Vacío | Usuario compartido que heredan los campos vacíos de DeviceList; solo en el archivo |
| `Password` | Vacío | Contraseña compartida que heredan los campos vacíos de DeviceList; solo en el archivo |

Con `Language=auto`, la configuración regional del sistema operativo selecciona el idioma de la interfaz y de los registros.
Una traducción externa utiliza el código de idioma de dos letras de esa configuración regional: por ejemplo, `de_DE.UTF-8` requiere `de.lang` junto al script.
Si no hay traducción adecuada, se utiliza el inglés.

`MonthlyArchive` sigue una regla ligeramente diferente: `false`/`no`/`0`/`off` desactiva el archivado; `true`/`yes`/`1`/`on` significa el primer día del mes; y los valores de `2` a `28` seleccionan el día requerido.

Cuando el Editor de configuración guarda el archivo, escribe
`MonthlyArchive=false` o el número seleccionado.

Los parámetros booleanos aceptan `true`/`false`, `yes`/`no`, `1`/`0`, y `on`/`off`
sin tener en cuenta el caso. El editor escribe `true`/`false`.

Los campos `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` y `Password` no aparecen en el Editor de configuración.

Al guardar el archivo, el editor escribe `IgnoreOxiAccess`, `encrypt_type`, y `SshPort`.
Conserva `Login` y `Password` solo si esas líneas ya estaban presentes en `option.cfg`, incluyendo líneas con valores vacíos.

Los campos `SshPort`, `Login` y `Password` pueden resultar útiles cuando todos los dispositivos usan el mismo puerto SSH y las mismas credenciales. En ese caso, cada entrada de `devicelist.cfg` solo necesita dos valores: el **nombre** del dispositivo y su **dirección IP**.

## Ejemplo sin limpieza o exportaciones sensibles

Este es un ejemplo de una política seleccionada, **no una lista de valores predeterminados de fábrica**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

Las primeras 19 claves se muestran en orden de escritura canónica.
Las líneas compatibles de `Login` y `Password` que ya existan se conservan después de ellas.

Los ajustes ausentes utilizan los valores integrados, no los del ejemplo anterior.
Por ejemplo, un archivo que contiene solo `Language=ru` no desactiva la limpieza y no cambia `show_sensitive=true`.

## Rutas

```ini
BackupRoot=backups
MainLogPath=logs
```

Estas entradas significan los directorios `backups` y `logs` junto al script.
Las rutas absolutas conservan su significado. `$HOME` y `~` no se expanden
como variables ni como referencias al directorio personal.

Si `BackupRoot` no existe, se crea durante la ejecución siempre que los permisos lo permitan.
El directorio raíz del sistema de archivos, `/`, está prohibido como almacenamiento.
Para los directorios existentes, el programa no corrige automáticamente la propiedad o los permisos.

Un valor no vacío de `MainLogPath` debe identificar un **directorio existente con permisos de escritura**.
La creación del propio `main.log` se aplaza hasta que se escribe la primera entrada;
esto no crea su directorio principal. Si no se puede escribir el registro, el procesamiento de las copias de seguridad
continúa con una advertencia. Este ajuste no mueve los registros de los dispositivos.

<a id="network-storage"></a>
## Red y almacenamiento separado

`UseNetFolder=true` se aplica al modo por lotes. La ruta debe estar cubierta por una entrada de montaje
distinta de la correspondiente a `/`. El almacenamiento independiente puede ser un almacenamiento de red,
un disco local o un montaje enlazado; el nombre de la opción no restringe el tipo de sistema de archivos.

Un directorio plano en el mismo sistema de archivos raíz no cumple con este requisito.
El script comprueba la disponibilidad y montaje, pero no llama `mount`, `umount`,
ni `sudo`, y tampoco recurre silenciosamente al almacenamiento local.

## Parámetros relacionados

Con `UseIncremental=false`, el script no compara la nueva copia de seguridad con la anterior y conserva cada archivo nuevo que se haya creado y verificado correctamente.
Este ajuste no afecta a la creación de la copia de seguridad ni al archivado mensual.
El valor predeterminado es `UseIncremental=true`. Si su `option.cfg` todavía no contiene este parámetro, la comparación permanece activada.

`backup_type=configuration` no utiliza el cifrado de las copias binarias
ni las operaciones de limpieza que las preceden. `backup_type=binary` no utiliza `export_format`
ni `show_sensitive`. `UseOxidized=false` no usa `OxidizedHome`.

Con `UseIdentityName=true`, si no se puede leer la identidad,
no se sustituye por `--device-name` ni por el nombre de DeviceList. Para utilizar un nombre especificado, deshabilite
`UseIdentityName`: consulte las [reglas de nomenclatura](DEVICES.md#device-names).

Con `MonthlyArchive=true`, el archivado se ejecuta cuando el script se inicia el día seleccionado del mes,
según la hora local del host; la hora concreta del día no importa.
Si el script no se ejecuta ese día, el intento mensual omitido no se recupera posteriormente.

[BACKUPS.md](BACKUPS.md#monthly-archive) explica qué archivos se incluyen en el ZIP, dónde se crea y cómo se denomina.
El período de datos, el corte y los intentos perdidos también se definen en
[BACKUPS.md](BACKUPS.md#monthly-archive).

La configuración puede contener secretos. Restrinja el acceso y no la incluya
en un repositorio público: [SECURITY.md](SECURITY.md).
