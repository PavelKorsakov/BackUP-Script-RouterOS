# Línea de comandos

[Índice](../README_ES.md)

## Sintaxis

```text
mikrotik-backup.sh [action] [parameters]
```

Los parámetros de la línea de comandos pueden utilizar una forma larga: `--parameter value` o `--parameter=value`.
También pueden utilizar una forma corta: `-p=value`. Sin embargo, si el **valor** comienza por `-`, solo se admite la forma con `=`: `--parameter=-value`.

Un parámetro desconocido, un argumento posicional o un valor ausente, explícitamente vacío o no válido produce el código de error `12` y detiene el script.

<br />

## Acciones

| Acción | Propósito |
|---|---|
| `-i` | Menú interactivo principal |
| `-b` | BackUP Master |
| `-e` | Editor de configuración (`option.cfg`) |
| `-h`, `--help` | Ayuda de la CLI |
| `-v`, `--version` | Versión del script |

El script no permite más de una opción de acción a la vez. Por ejemplo, `mikrotik-backup.sh -i -b` se detiene con el código de error `12`.

<br />

## Parámetros

| Parámetro | Valor | Propósito |
|---|---|---|
| `--device-name` | Nombre | Nombre del dispositivo cuando `UseIdentityName=false` |
| `--address` | Dirección IP o nombre DNS | Dirección del dispositivo RouterOS |
| `--user` | Usuario | Usuario del dispositivo RouterOS |
| `--password` | Contraseña | Contraseña del dispositivo RouterOS |
| `--port` | `1`–`65535` | Puerto SSH del dispositivo; valor predeterminado `22` |
| `--language` | `auto` o dos letras ASCII | Idioma de la interfaz y de los registros del script |
| `--use-oxidized` | Valor booleano * | Importar la lista de dispositivos de Oxidized |
| `--oxidized-home` | Ruta | Directorio de configuración de Oxidized que contiene `config` y `router.db` |
| `--use-identity-name` | Valor booleano * | Obtener el nombre de identidad de RouterOS |
| `--backup-root` | Ruta | Directorio raíz para almacenar las copias de seguridad |
| `--use-net-folder` | Valor booleano * | Comprobar el montaje en el modo por lotes |
| `--monthly-archive` | `false` o un número de `1` a `28` * | Habilitar el archivado mensual basado en el calendario |
| `--log-level` | `0`, `1`, `2`, `3` | Nivel de detalle de los registros y de la salida del terminal |
| `--main-log-path` | Ruta | Directorio únicamente para `main.log` |
| `--backup-type` | `configuration`, `binary`, `both` | Formatos de copia de seguridad que se obtendrán |
| `--export-format` | `compact`, `terse`, `verbose` | Formato de exportación de texto |
| `--show-sensitive` | Valor booleano * | Incluir valores sensibles en la exportación |
| `--encrypt` | Contraseña no vacía | Cifrar `.backup` con AES-SHA256 |
| `--clear-dns-cache` | Valor booleano * | Limpiar la caché DNS antes de una copia de seguridad binaria |
| `--clear-console-history` | Valor booleano * | Limpiar el historial de la consola antes de una copia de seguridad binaria |

`*` Los valores booleanos son `true` o `false`; el script también acepta `yes`/`no`, `1`/`0`, y `on`/`off`, sin tener en cuenta el caso.
Para `backup-type`, también se admiten `config` y `conf` como sinónimos de `configuration`.

Formas de conexión cortas:

```text
-a=VALUE    equivale a --address VALUE
-u=VALUE    equivale a --user VALUE
-p=VALUE    equivale a --password VALUE
```

<br />

<a id="execution-mode"></a>
## Ejecutar el script desde la línea de comandos

El script puede crear una copia de seguridad de un solo dispositivo, pero para ello necesita al menos tres parámetros:
la **dirección IP**, el **usuario** y la **contraseña** del dispositivo. En otras palabras, el siguiente comando ya es válido:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Todos los demás parámetros enumerados anteriormente son opcionales aquí.
*(N.B. Un punto muy importante: el script NO está diseñado para combinar estos tres datos de conexión con una opción de **acción**.)*

**¡Un detalle más!!!**
Para una ejecución de un solo dispositivo, los tres parámetros de conexión deben proporcionarse mediante la CLI. El script no toma de `option.cfg` un usuario ni una contraseña que falten.

<br />

## Orden de prioridad

Las copias de seguridad normales, tanto de un solo dispositivo como por lotes, utilizan el orden descrito en [OPTIONS.md](OPTIONS.md):
**Valores integrados** → **Líneas válidas de `option.cfg`** → **CLI**

Si un parámetro ya está presente en `option.cfg`, pero una ejecución concreta necesita otro valor, proporciónelo mediante la CLI. No es necesario reescribir el archivo de configuración.

Una ejecución de un solo dispositivo no utiliza la lista de dispositivos ni la importación desde Oxidized. Las demás opciones de `option.cfg` siguen aplicándose, salvo que los parámetros de la línea de comandos las sustituyan.

**BackUP Master utiliza su propio orden para rellenar el formulario.**
Los campos normales utilizan los valores integrados y los parámetros suministrados mediante la CLI, no `option.cfg`. `UseIncremental` es la excepción: se hereda del archivo o adopta su valor predeterminado.
Los valores seleccionados de `LogLevel` y `MainLogPath` se conservan durante la ejecución, mientras que el archivado mensual queda deshabilitado. Consulte [INTERACTIVE.md](INTERACTIVE.md) para obtener más información sobre BackUP Master.

<br />

## Parámetros de línea de comandos por propósito

### Conexión y nombre de dispositivo

| Opción | Valor | Propósito |
|---|---|---|
| `--address` | dirección IP o nombre DNS | Dirección del dispositivo RouterOS |
| `--user` | Usuario | Usuario del dispositivo RouterOS |
| `--password` | Contraseña | Contraseña del dispositivo RouterOS |
| `--port` | `1` a `65535` | Puerto SSH del dispositivo; valor predeterminado `22` |
| `--device-name` | Nombre | Nombre del dispositivo cuando `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Obtener el nombre de identidad de RouterOS |

Para usar su propio nombre, especifique `--use-identity-name false` y `--device-name NAME` juntos.

<br />

### Formato y contenido de copia de seguridad

| Opción | Valor | Propósito |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Formatos de copia de seguridad que se obtendrán |
| `--export-format` | `compact`, `terse`, `verbose` | Formato de exportación de texto |
| `--show-sensitive` | `true` / `false` | Incluir valores sensibles en la exportación |
| `--encrypt` | Contraseña no vacía | Cifrar `.backup` con AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Limpiar la caché DNS antes de una copia de seguridad binaria |
| `--clear-console-history` | `true` / `false` | Limpiar el historial de la consola antes de una copia de seguridad binaria |

Para `--backup-type`, `config` y `conf` también significan `configuration`.

*(N.B. `UseIncremental` no tiene una opción propia en la CLI. Configúrelo en `option.cfg`, en el Editor de configuración o en BackUP Master. Su propósito se describe en [OPTIONS.md](OPTIONS.md).)*

<br />

### Almacenamiento, archivado y registros

| Opción | Valor | Propósito |
|---|---|---|
| `--backup-root` | Ruta | Directorio raíz para almacenar las copias de seguridad |
| `--use-net-folder` | `true` / `false` | Comprobar el montaje en el modo por lotes |
| `--monthly-archive` | `false` o un número de `1` a `28` | Habilitar el archivado mensual basado en el calendario |
| `--log-level` | `0`, `1`, `2`, `3` | Nivel de detalle de los registros y de la salida del terminal |
| `--main-log-path` | Directorio | Directorio únicamente para `main.log` |

`--monthly-archive` tiene su propia regla: `true`/`yes`/`1`/`on` significa el primer día del mes, mientras `false`/`no`/`0`/`off` desactiva el archivado. Los valores de `2` a `28` seleccionan el día requerido.

La opción selecciona el día de archivado; no ejecuta el archivado de inmediato. Consulte [BACKUPS.md](BACKUPS.md#monthly-archive) para conocer las reglas de este modo.

Para `--main-log-path`, especifique un directorio, no una ruta completa que termina en `main.log`. Este ajuste no afecta los registros de dispositivos.

<br />

### Origen de la lista de dispositivos e idioma

| Opción | Valor | Propósito |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Importar la lista de dispositivos de Oxidized |
| `--oxidized-home` | Ruta | Directorio de configuración de Oxidized que contiene `config` y `router.db` |
| `--language` | `auto` o un código de dos letras | Idioma de la interfaz y de los registros del script |

Con `--language auto`, la configuración regional del sistema operativo selecciona el idioma. Puede elegir uno explícitamente, como `ru`, `en` o `de`. El ruso y el inglés no requieren archivos de traducción independientes; las demás traducciones se cargan desde archivos situados junto al script. Si no existe una traducción adecuada, se utiliza el inglés.
Consulte [LOCALIZATION.md](LOCALIZATION.md) para obtener más información.

<br />

## Ejemplos

**¡Atención!!!**
De forma predeterminada están habilitados la inclusión de datos sensibles en las exportaciones, la limpieza de la caché DNS y el borrado del historial de la consola antes de crear una copia de seguridad binaria. Los siguientes ejemplos para un solo dispositivo deshabilitan las tareas de limpieza y la inclusión de datos sensibles.

*(N.B. Las contraseñas suministradas mediante la CLI pueden quedar visibles en el historial del shell y en los argumentos de los procesos. Esto también se aplica a la contraseña de cifrado de `.backup`, que puede aparecer en los argumentos del proceso hijo `ssh`. Consulte [SECURITY.md](SECURITY.md) para obtener más información.)*

### Solo configuración `.rsc`, sin datos sensibles

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Ambos formatos, un nombre de dispositivo personalizado y sin tareas de limpieza

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Copia de seguridad binaria cifrada

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Ejecución por lotes con un directorio independiente y registro detallado

Este ejemplo supone que `option.cfg` y la lista de dispositivos ya se han preparado:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Los ajustes restantes de esta ejecución por lotes proceden de `option.cfg` y de los valores integrados.

<br />

## Si se rechaza un comando

Una opción desconocida, un argumento posicional adicional o un valor ausente o no válido provoca el error `12`. No se inicia ninguna copia de seguridad. Utilice `-h` para comprobar cómo se escribe la opción.

**No se pueden pasar valores vacíos mediante la CLI.**
`--encrypt=''` y `--main-log-path=''` se rechazan. Defina valores vacíos mediante `encrypt=` y `MainLogPath=` en `option.cfg` o a través del Editor de configuración.

Los códigos de resultados y sus significados se enumeran en [Solución de problemas](TROUBLESHOOTING.md#result-codes).
