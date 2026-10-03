# Registro

[Índice](../README_ES.md)

## Registros principales y registros de dispositivos

El script registra su progreso general en el registro principal, `main.log`, mientras que los detalles del trabajo con cada dispositivo se guardan en un registro de dispositivo separado.

En `main.log` puede ver cómo se preparó la lista de dispositivos, seguir el procesamiento por lotes y revisar los resultados de los dispositivos procesados. También se registran aquí los errores que ocurren antes de identificar un dispositivo concreto.

El registro de un dispositivo contiene información sobre la obtención de archivos `.rsc` y `.backup`, los reintentos, la comparación de copias y el archivado. En otras palabras, si necesita saber qué ocurrió durante la copia de un dispositivo concreto, consulte su registro. Estos detalles no se duplican en `main.log`.

<br />

## Dónde se almacenan los registros

De forma predeterminada, el registro principal se almacena en el directorio `backups` junto al script. Los registros del dispositivo se almacenan junto a sus copias de seguridad:

| Registro | Ubicación |
|---|---|
| Registro principal | `<BackupRoot>/main.log` |
| Dispositivo en modo por lotes | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Dispositivo en una ejecución individual | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

En el modo por lotes, las entradas nuevas se añaden al mismo registro del dispositivo. Para una copia de seguridad de un solo dispositivo, el nombre del registro contiene la misma fecha y hora que los nombres de los archivos de copia de esa ejecución.

### Un directorio separado para main.log

Si prefiere mantener el registro principal separado de las copias de seguridad, especifique el directorio en el ajuste `MainLogPath` en `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

El registro se escribirá en `/var/log/mikrotik-backup/main.log`. Los registros del dispositivo permanecerán en sus lugares habituales.

Un valor vacío `MainLogPath=` utiliza el `BackupRoot` actual. Una ruta relativa, como `MainLogPath=logs`, se refiere a un directorio situado junto al script, no dentro del almacenamiento de las copias.

*(N.B. `MainLogPath` especifica un directorio, no un nombre de archivo completo. El directorio debe existir y permitir la escritura al usuario que ejecuta el script.)*

<br />

## Detalles de registro

El ajuste `LogLevel` controla cuánta información se muestra y se registra. Su valor predeterminado es `2`:

| Valor | Progreso en el terminal | Entradas en archivos de registro |
|---|---|---|
| `0` | Solo errores | Solo errores |
| `1` | Etapas principales y sus resultados | Registro breve |
| `2` | Principales etapas y sus resultados | Registro detallado |
| `3` | Principales etapas y suboperaciones actuales | Registro detallado |

**Los errores se registran en todos los niveles.** Un registro breve contiene las etapas principales y sus resultados; uno detallado también recoge las operaciones realizadas dentro de esas etapas.

Puede cambiar el nivel en `option.cfg` o mediante el Editor de configuración:

```ini
LogLevel=3
```

Para cambiarlo durante una única ejecución por lotes ya configurada, utilice la CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Esto no cambia el valor en el archivo de opciones. De la misma manera, `--main-log-path` puede establecer la ubicación principal de registro para la ejecución actual.

BackUP Master no tiene campos independientes para `LogLevel` ni `MainLogPath`. Utiliza los ajustes de registro vigentes para la ejecución actual.

<br />

## Aspecto de los registros

Los registros son archivos de texto normales. Cada entrada incluye la fecha y la hora según el reloj del host que ejecuta el script. Los colores y los indicadores de progreso no se escriben en el archivo.

Entradas de ejemplo en `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Procesando dispositivos por lotes
[2026-10-01 01:00:15] [PID:12345] [OK] Procesando dispositivos por lotes
```

El registro principal también incluye el PID del proceso. Esto permite distinguir las entradas escritas por varias instancias del script que se ejecutan al mismo tiempo.

El PID no se añade al registro del dispositivo. Este es un extracto de un registro detallado:

```text
[2026-10-01 01:00:05] Obteniendo copia de seguridad binaria
[2026-10-01 01:00:06] [1] Borrando la caché DNS
[2026-10-01 01:00:07] [2] Borrando el historial de consola
[2026-10-01 01:00:12] [OK] Obteniendo copia de seguridad binaria
```

`[OK]` significa que la operación terminó correctamente. Los errores se marcan con `[ER]` e incluyen su código, por ejemplo `[53]`. Las suboperaciones se numeran `[1]`, `[2]` y así sucesivamente, comenzando de nuevo dentro de cada etapa principal.

Si un reintento termina correctamente después de un intento fallido, el registro conserva tanto el error anterior como el resultado correcto posterior.

Las entradas de registro utilizan el mismo idioma que la interfaz, seleccionada por el ajuste `Language`. Para más información sobre la elección de un idioma y el uso de traducciones, vea [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Salida de la terminal

Durante una ejecución manual, el progreso es visible en pantalla. Mientras una operación está en curso, aparece a su lado un indicador de espera. Cuando termina, el indicador cambia a un `[OK]` verde o a un `[ER]` rojo acompañado de un código de error.

Los niveles `1` y `2` muestran las etapas principales. En el nivel `3`, la suboperación actual aparece debajo de la etapa en curso y cambia conforme avanza el trabajo. En el modo por lotes, la pantalla también identifica el dispositivo que se está procesando.

*(N.B. Cuando el script se ejecuta sin un terminal —por ejemplo, desde un programador de tareas o con la salida redirigida—, no se muestra esta salida en pantalla. La escritura en los archivos de registro continúa en el nivel seleccionado.)*

<br />

## Acumulación y archivado de registros

Se crea un archivo de registro cuando se escribe su primera entrada. Con `LogLevel=0` y sin errores, no se crean nuevos archivos de registro, mientras que los existentes permanecen inalterados.

El registro principal y los registros acumulativos de los dispositivos en modo por lotes se amplían en lugar de sobrescribirse en cada ejecución. Una línea en blanco separa las ejecuciones sucesivas.

`main.log` no se archiva ni se elimina por antigüedad. Su rotación queda a cargo del administrador.

Cuando se activa el archivado mensual, el registro acumulativo completo del dispositivo en modo por lotes se incluye en el ZIP junto con sus copias de seguridad. Una vez guardado correctamente el ZIP, el registro archivado se elimina del directorio del dispositivo; el resultado del archivado y el trabajo posterior se escriben en un nuevo archivo de registro.

Si el mismo ZIP vuelve a actualizarse, el historial que contiene se amplía en vez de sustituirse por un registro nuevo. Si el archivo no puede guardarse, el registro anterior permanece en su sitio y el error se anota en él.

Los registros de las ejecuciones de un solo dispositivo mediante la CLI se archivan junto con las copias del directorio compartido. El archivado en ambos modos se describe en [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Si un registro no se puede escribir

Los permisos insuficientes, un directorio no disponible u otro error de escritura del registro no detienen la propia copia de seguridad. El script anota una advertencia y continúa siempre que sea posible.

Un `main.log` no disponible se notifica una vez por ejecución, y un registro de dispositivo no disponible una vez mientras se procesa ese dispositivo. Si el registro principal está disponible, se registra un fallo de escritura de registro de dispositivo allí.

Si no hay otros errores, la ejecución sale con código `1`, lo que significa que completó con una advertencia. Esta advertencia no reemplaza un error de la operación de copia de seguridad en sí.

Para consultar los códigos de resultado y encontrar la causa de un error, vea [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(N.B. El nivel detallado `3` no registra contraseñas ni comandos de conexión completos. Para obtener información sobre la protección de las credenciales y los archivos del script, consulte [SECURITY.md](SECURITY.md).)*
