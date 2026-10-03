# Solución de problemas

[Índice](../README_ES.md)

## Dónde empezar

Si la copia de seguridad no se inició o terminó con un error, consulte primero los registros. `main.log` contiene las etapas generales de la ejecución, mientras que los detalles de la copia de un dispositivo concreto se escriben en un registro independiente para ese dispositivo.

Busque entradas marcadas con `[ER]` y un código de error. Los códigos se explican [más abajo](#result-codes), y las ubicaciones de los registros se describen en [LOGGING.md](LOGGING.md).

Utilice estos comandos para mostrar la versión instalada del script y la referencia de opciones:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Para repetir una ejecución ya configurada por lotes con salida detallada:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

El segundo comando muestra el resultado de la ejecución completa. No cambia el nivel de registro en `option.cfg`.

<br />

## El script no inicia una copia de seguridad

### El editor abrió en lugar de una copia de seguridad

Cuando el script se inicia sin opciones, esto significa que `option.cfg` no existe en el directorio del script o no contiene ajustes utilizables. Un archivo vacío, uno que solo contenga comentarios o uno que incluya únicamente parámetros desconocidos o no válidos no cambia el resultado.

Abra el Editor de configuración, seleccione los ajustes necesarios, guarde el archivo y vuelva a ejecutar el script:

```bash
mikrotik-backup.sh -e
```

Guardar un dispositivo mediante BackUP Master crea `devicelist.cfg`, pero no sustituye la preparación de `option.cfg`.

*(N.B. Si tal ejecución es iniciada por un programador de tareas, el editor no puede abrir y el script sale con código `31`. Los ajustes para una ejecución automática deben estar preparados con antelación.)*

### Error de opción, código 12

Compruebe los nombres de las opciones, sus valores y la combinación de acciones. Posibles causas incluyen una opción desconocida, un valor vacío, múltiples acciones diferentes solicitadas a la vez, o credenciales incompletas para una conexión de un solo dispositivo.

Una ejecución de un solo dispositivo mediante la CLI requiere una dirección, un usuario y una contraseña. Las credenciales que falten no se obtienen de `option.cfg`.

Las opciones cortas de conexión deben utilizar `=`: `-a=`, `-u=` y `-p=`. Recuerde que `-p` especifica la contraseña; utilice `--port` para el puerto SSH.

Todas las opciones y ejemplos aceptados se enumeran en [CLI.md](CLI.md).

### No se puede leer `option.cfg`, código 21

Asegúrese de que `option.cfg` sea un archivo normal y legible por el usuario que ejecuta el script. También se permite un enlace simbólico legible a dicho archivo.

Un archivo ausente y uno ilegible son situaciones diferentes. Si el archivo existe, pero no se puede leer, el script no continúa con los ajustes predeterminados.

### Falta una dependencia, código 30

Compruebe las utilidades principales con:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

El modo por lotes con `UseNetFolder=true` también requiere `findmnt`. El día del archivado mensual se necesitan `zip`, `unzip` y GNU `mv`. Copiar el comando de consola desde BackUP Master requiere GNU `base64` compatible con `--wrap=0`.

**No basta con que la utilidad esté instalada.** La versión de OpenSSH debe admitir las opciones utilizadas y `scp -O`; GNU `timeout` debe admitir `--signal` y `--kill-after`.

La lista completa de dependencias y los comandos de instalación se encuentran en [INSTALL.md](INSTALL.md#dependencias).

### El menú no se abre, código 31

El menú, el editor y BackUP Master requieren un terminal y una utilidad `stty` funcional. No los inicie mediante una canalización ni con la entrada o la salida estándar redirigidas.

Si el mensaje indica que el terminal es demasiado pequeño, amplíe la ventana. Las pantallas principales necesitan al menos 46 columnas de ancho y las instrucciones integradas necesitan 80. Las listas largas del editor y de BackUP Master se desplazan con las teclas de flecha; no es necesario que todo el formulario quepa de una vez en la pantalla.

Los controles de interfaz se describen en [INTERACTIVE.md](INTERACTIVE.md).

<br />

## La lista de dispositivos no se carga

### El archivo `devicelist.cfg`, códigos 22 y 23

Compruebe la ubicación del archivo y el acceso a él. `devicelist.cfg` debe estar junto a `mikrotik-backup.sh`, independientemente del directorio desde el que inicie el script.

Los campos se separan mediante un carácter TAB real, no mediante espacios. Un dispositivo debe tener un nombre, una dirección, un usuario, una contraseña y un puerto SSH válido. Las credenciales compartidas pueden proceder de `option.cfg` cuando los campos correspondientes de la entrada estén vacíos.

Las entradas no válidas se omiten con una advertencia. Si no quedan dispositivos admisibles, no hay nada de lo que crear una copia y el script termina con un error de lista.

Compruebe también si hay conexiones duplicadas o dispositivos distintos con el mismo nombre. El formato del archivo, la herencia de credenciales y las reglas para tratar duplicados se describen en [DEVICES.md](DEVICES.md).

### Importación de Oxidized, códigos 24 y 25

El código `24` significa que no se pudo leer `config` o `router.db` en `OxidizedHome`. El código `25` se refiere al contenido: un esquema no compatible, datos no válidos o ausencia de dispositivos MikroTik elegibles.

Compruebe la ruta, el acceso a ambos archivos, la fuente `csv`, el delimitador, el mapa de columnas y la definición del modelo `routeros`. Los datos se leen específicamente de `<OxidizedHome>/router.db`; el ajuste `source.csv.file` de Oxidized no cambia esa ruta.

Con `IgnoreOxiAccess=true`, el script puede continuar con la lista válida anterior. El fallo de importación sigue formando parte del resultado de la ejecución. Con `false`, la lista antigua no se utiliza en esa ejecución.

La configuración de importación se describe en [DEVICES.md](DEVICES.md#importación-desde-oxidized).

<br />

## Almacenamiento y bloqueo

### El bloqueo está ocupado, código 32

Compruebe si otra tarea ya está utilizando el mismo directorio de copias de seguridad. Entre ejecuciones del mismo usuario, una ejecución por lotes entra en conflicto con cualquier otra copia que utilice el mismo `BackupRoot`. Tampoco pueden ejecutarse simultáneamente en ese almacenamiento dos ejecuciones individuales del mismo dispositivo.

Espere a que termine la tarea activa y vuelva a ejecutar el script.

**No elimine los archivos de bloqueo para «liberar» el almacenamiento.** Permanecen después de que el script termine; es el propio proceso el que mantiene el bloqueo. La presencia de un archivo en `/tmp/mikrotik-backup-${UID}/` no significa que el bloqueo esté ocupado.

### No hay acceso al directorio

Compruebe la ruta `BackupRoot`, los permisos del usuario, el espacio libre y la disponibilidad del propio dispositivo de almacenamiento. Las rutas relativas se resuelven desde el directorio del script. La raíz del sistema de archivos, `/`, no puede utilizarse para almacenar copias de seguridad.

Si el script se ejecutó anteriormente como root y ahora se ejecuta como **bsmt**, es posible que ese usuario no tenga acceso a los directorios y archivos antiguos. La preparación de los permisos se describe en [INSTALL.md](INSTALL.md#ejecutar-el-script-automáticamente).

El modo por lotes con `UseNetFolder=true` requiere un montaje independiente. Compruébelo con:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Sustituya la primera ruta por la suya. Si ambas rutas pertenecen a la misma entrada de montaje, un directorio normal del sistema de archivos raíz no cumple el requisito de `UseNetFolder=true`. El script no monta el almacenamiento por sí mismo.

El código `64` indica un fallo en el directorio o en un archivo del dispositivo mientras el almacenamiento compartido sigue disponible. El procesamiento de otros dispositivos puede continuar. El código `65` significa que el almacenamiento compartido se perdió o pasó a un estado no válido, y detiene el resto del lote.

Las reglas de almacenamiento de redes se describen en [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Errores mientras trabaja con un dispositivo

### SSH y transferencia de archivos, códigos 40–43

Compruebe la dirección del dispositivo, la disponibilidad de su servicio SSH, el usuario, la contraseña y el puerto. Si no se especifica ningún puerto en `devicelist.cfg`, se utiliza el valor `SshPort` de la configuración; su valor predeterminado es `22`.

El usuario RouterOS debe tener permiso para las operaciones seleccionadas: exportar configuración, crear y recuperar copias de seguridad, borrar archivos temporales y realizar cualquier operación de limpieza habilitada.

**Y aquí hay un matiz!!!** Que la conexión funcione con su comando SSH habitual no significa que el script utilice los mismos ajustes. El script funciona con contraseña y no utiliza el agente SSH, las claves ni el archivo `~/.ssh/config` habitual. Los archivos se obtienen mediante `scp -O`.

El código `40` se refiere a la conexión o al transporte SSH/SCP, el `41` a la autenticación, el `42` a un comando de RouterOS o a su respuesta y el `43` a la transferencia de archivos. Consulte [SECURITY.md](SECURITY.md#conexión-a-routeros).

### Error de nombres, códigos 50 y 52

El código `50` significa que el nombre final del dispositivo no es válido. Revise el origen del nombre seleccionado y el contenido de los paréntesis: en la versión actual se utiliza como nombre el primer fragmento completo y no vacío entre paréntesis.

Tras el procesamiento, el nombre debe contener entre 1 y 32 caracteres. Los nombres demasiado largos no se truncan. También se rechazan nombres reservados como `CON` y `NUL`.

El código `52` significa que el nombre final duplica el de otro dispositivo de la misma ejecución. La comparación no distingue entre mayúsculas y minúsculas: `Router-A` y `router-a` se consideran idénticos.

Las reglas de la fuente de nombre y procesamiento se describen en [DEVICES.md](DEVICES.md#device-names).

### Falló la validación de la copia, códigos 51 y 53

El código `51` se aplica a `.rsc` y el código `53` a `.backup`. Falló la validación del archivo obtenido: por ejemplo, está vacío o su tamaño no coincide con el del archivo del dispositivo.

Compruebe la etapa en la que ocurrió el error, junto con el espacio libre y los permisos en el host y en RouterOS. Después de un intento fallido, el script vuelve a intentarlo una vez transcurridos 2 segundos. Los intentos son independientes para ambos formatos, por lo que un archivo puede obtenerse correctamente mientras el otro falla.

Una advertencia por no haber podido borrar un archivo temporal de RouterOS después de obtener correctamente la copia no significa por sí sola que la copia local esté dañada.

<br />

## No hay ninguna copia nueva, pero tampoco hay errores

Compruebe primero `UseIncremental`. Cuando se habilita la comparación, se puede eliminar una nueva copia de seguridad como un duplicado mientras se conserva la anterior. Para `.rsc`, los contenidos se comparan sin la fecha en el encabezado estándar; para `.backup`, solo se comparan los tamaños de los archivos.

Con `UseIncremental=false`, se mantiene una nueva copia de seguridad válida sin esta comparación.

Tenga en cuenta que dos ejecuciones para el mismo dispositivo y directorio dentro del mismo minuto usan el mismo nombre de archivo. No se crea una versión separada para la segunda ejecución.

Si el archivado mensual se ejecutó ese día, compruebe también el ZIP. En el modo de un solo dispositivo mediante la CLI, la copia nueva también puede encontrarse dentro. Consulte [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## No apareció el archivo ZIP mensual

Verifique el valor `MonthlyArchive` y la fecha de ejecución en la hora local del host. `false` desactiva el archivado; `true` o `1` selecciona el primer día, mientras que un número de `2` a `28` selecciona ese día del mes.

La hora de ejecución del día seleccionado no importa. Si se pierde ese día, una ejecución normal posterior no recupera el intento. No se realiza ninguna ejecución adicional del archivado durante ese mismo día ni durante el resto del mes; el siguiente intento solo tendrá lugar en la siguiente fecha mensual programada. El archivado mensual no se realiza mediante BackUP Master.

Si no hay nada que archivar, no se crea un ZIP vacío.

### ¿Dónde encontrar el ZIP

El nombre del archivo corresponde al día calendario anterior. Por ejemplo, una ejecución el 1 de octubre de 2026 crea `30.09.2026.zip`:

| Modo | Ubicación |
|---|---|
| Por lotes | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Dispositivo único mediante la CLI | `<BackupRoot>/30.09.2026.zip` |

El nombre del directorio `archive/` se escribe en minúsculas. Otra ejecución el mismo día actualiza el mismo ZIP.

### El archivado terminó con un error

Para los códigos `70` y `71`, compruebe el registro del dispositivo, el acceso al directorio de archivado, el espacio libre y el estado de cualquier ZIP existente. Se necesita espacio tanto en el almacenamiento como en el directorio local `/tmp`.

En un disco local, el directorio `archive/` debe pertenecer al usuario del script y tener el modo `0700`. En el modo por lotes con almacenamiento de red verificado y `UseNetFolder=true`, un propietario distinto o los permisos asignados por el NAS no constituyen por sí solos un motivo de fallo. Los errores de almacenamiento durante el archivado también pueden producir los códigos `64` o `65`.

Compruebe un archivo existente con el siguiente comando, sustituyendo su ruta real:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Los archivos de origen no se eliminan hasta que se haya guardado un ZIP verificado. Si el ZIP se guarda, pero algunos archivos de origen no pueden eliminarse, tanto el ZIP como los archivos no eliminados permanecen. Un ZIP existente que esté dañado no se sustituye automáticamente por uno nuevo.

**No elimine las copias de seguridad ni los registros restantes hasta comprobar el contenido del ZIP.** La secuencia de archivado se describe en [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## No hay registros ni salida en pantalla

Con `LogLevel=0` y sin errores, no se crean registros nuevos. En caso contrario, compruebe los valores seleccionados de `BackupRoot` y `MainLogPath`, así como los permisos de escritura.

Un `MainLogPath=` vacío deja `main.log` en `BackupRoot`. Si se especifica un directorio separado, debe existir y ser accesible para el usuario del script. Este ajuste no mueve los registros de los dispositivos.

Después del archivado mensual, el historial anterior del dispositivo está en el ZIP. El trabajo posterior se escribe en un registro nuevo junto a las copias de seguridad.

Cuando el script funciona desde un programador de tareas o con su salida redirigida, el registro en pantalla con su indicador y marcas de color no aparece; el registro en archivos continúa.

Un error al escribir un registro no detiene la propia copia de seguridad, pero aparece como advertencia en el resultado de la ejecución. Consulte [LOGGING.md](LOGGING.md) para obtener más información.

<br />

<a id="language-problems"></a>
## No se aplicó una traducción

Compruebe el idioma seleccionado y la ubicación del archivo. Por ejemplo, `Language=de` requiere un archivo normal y legible llamado `de.lang` junto a `mikrotik-backup.sh`, no dentro del directorio `lang/`. Los enlaces simbólicos no se utilizan como archivos de traducción.

Con `Language=auto`, el entorno del sistema operativo determina el idioma. Puede seleccionarlo explícitamente para una sola ejecución, por ejemplo al ver la ayuda:

```bash
mikrotik-backup.sh --language=de --help
```

Los mensajes no traducidos se muestran en inglés. Las líneas mal formadas del archivo se omiten. Los archivos llamados `ru.lang` y `en.lang` no sustituyen a las traducciones integradas.

El formato de línea, nombres clave y reglas para cargar una traducción se describen en [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Un ajuste no surte efecto

Compruebe el nombre del ajuste, el valor aceptado y las entradas duplicadas en `option.cfg`. Cuando un ajuste se repite, prevalece el último valor utilizable. Los nombres de las claves no distinguen entre mayúsculas y minúsculas, pero los guiones y los guiones bajos no son intercambiables.

Una opción de la CLI anula el valor correspondiente del archivo. Para las ejecuciones ordinarias de un solo dispositivo y por lotes, el orden es:

**Valores integrados** → **líneas válidas de `option.cfg`** → **CLI**

BackUP Master rellena el formulario de otra manera: los campos normales proceden de los valores integrados y de la CLI, no del archivo de opciones. `UseIncremental` es la excepción. Los ajustes de registro del archivo también se respetan cuando se ejecuta una copia de seguridad mediante BackUP Master.

Las reglas de lectura de los ajustes se encuentran en [OPTIONS.md](OPTIONS.md), y el comportamiento de BackUP Master se explica en [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Códigos de resultados

| Código | Significado |
|---:|---|
| `0` | Éxito sin errores registrados o advertencias |
| `1` | Completado con advertencias y sin errores de ejecución registrados |
| `12` | Error en opciones de la CLI, sus valores o su combinación |
| `21` | No se pudo leer `option.cfg` |
| `22` | No se pudo obtener la lista de dispositivos |
| `23` | Lista de dispositivos no válida o sin entradas elegibles |
| `24` | No se pudieron leer los archivos de Oxidized |
| `25` | Esquema no compatible o datos de Oxidized no válidos; no hay entradas MikroTik utilizables |
| `30` | Falta una utilidad necesaria o no admite las funciones requeridas |
| `31` | Terminal no disponible, error `stty` o insuficiente tamaño de la ventana |
| `32` | Otra ejecución mantiene el bloqueo necesario |
| `33` | Ruta u objeto de almacenamiento no válido para una operación de un solo dispositivo |
| `34` | No se puede crear ni preparar el directorio de un solo dispositivo |
| `35` | Error al acceder o validar un objeto auxiliar local, incluido un bloqueo |
| `36` | El almacenamiento de una ejecución de un solo dispositivo no superó la comprobación de disponibilidad previa a la obtención de archivos |
| `37` | No se puede escribir o reemplazar un archivo de servicio |
| `40` | Error de conexión o transporte SSH/SCP |
| `41` | Error de autenticación en el dispositivo |
| `42` | Error en un comando de RouterOS o en la respuesta esperada |
| `43` | Error de transferencia de archivos mediante SCP |
| `50` | Nombre del dispositivo final inválido |
| `51` | Falló la validación del archivo `.rsc` |
| `52` | Nombres finales de dispositivo duplicados |
| `53` | Falló la validación del archivo `.backup` |
| `61` | Almacenamiento compartido no disponible mientras se prepara una ejecución por lotes |
| `62` | No se pudo confirmar ni activar un montaje separado para `UseNetFolder=true` |
| `63` | Falló la preparación o validación del directorio compartido del lote |
| `64` | Error de almacenamiento de dispositivos o archivos mientras que el almacenamiento compartido sigue disponible |
| `65` | El almacenamiento compartido se perdió o se hizo inválido durante la ejecución; se detiene el procesamiento por lotes |
| `70` | Error al crear o actualizar un archivo ZIP |
| `71` | Falló la validación del ZIP o del objeto ZIP de destino |
| `80` | Error interno o requisito del sistema no satisfecho, incluida la capacidad `C.UTF-8` |
| `81` | Error interno del controlador MikroTik |
| `129` | Terminado por la señal HUP |
| `130` | Terminado por la señal INT, por ejemplo pulsando Ctrl+C |
| `143` | Terminado por la señal TERM |

El código final refleja el primer error de ejecución registrado. La advertencia `1` queda sustituida por el primer error real, y un éxito posterior no lo borra. Por tanto, el código final no tiene por qué coincidir con el último mensaje del registro.

Si un reintento de obtención tiene éxito, la etapa puede terminar con `[OK]` aunque el error del primer intento permanezca en el registro. Un código final distinto de cero en una ejecución por lotes tampoco significa que todos los dispositivos hayan fallado: inspeccione cada resultado por separado.

Para el código `80`, preste atención a los requisitos del sistema: GNU Bash 4.4 o posterior y una configuración regional `C.UTF-8` funcional. Consulte [INSTALL.md](INSTALL.md#requisitos-del-host).

<br />

## Si necesita ayuda

Proporcione la versión del script, el sistema operativo y la versión de Bash, cómo se inició el script, su código de salida y el extracto pertinente del registro. Para un problema con un dispositivo, incluya su registro de dispositivo; para un error al preparar una ejecución, comience con `main.log`.

**No envíe contraseñas reales ni archivos completos de configuración de trabajo.** Antes de enviar registros, capturas de pantalla o comandos, compruebe si contienen datos sensibles. Consulte [SECURITY.md](SECURITY.md).

Puede contactar con el autor mediante los datos de la [presentación del producto](../README_ES.md#contactar-con-el-autor).
