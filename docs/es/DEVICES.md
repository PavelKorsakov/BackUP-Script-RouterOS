# Lista de dispositivos

[Índice](../README_ES.md)

## Dispositivos de los que se harán copias: el archivo `devicelist.cfg`

Como indica su nombre, `devicelist.cfg` enumera los dispositivos de una copia de seguridad por lotes y los datos necesarios para conectarse a ellos.
Coloque el archivo directamente junto a `mikrotik-backup.sh`.
Puede crear `devicelist.cfg` manualmente o mediante BackUP Master.
Una tercera opción es útil cuando Oxidized se ejecuta en el mismo servidor. Después de añadir la configuración correspondiente al archivo de opciones,
el script crea dinámicamente `devicelist.cfg` en cada ejecución utilizando los datos necesarios de los archivos de configuración de Oxidized.

<br />

## Creación y edición de la lista

Para crear la lista mediante BackUP Master, ejecute:

```bash
mikrotik-backup.sh -b
```

Rellene el nombre, la dirección, el usuario, la contraseña y el puerto SSH del dispositivo → seleccione **2. Guardar el dispositivo en devicelist.cfg**.
BackUP Master crea el archivo con la entrada necesaria, o bien añade o actualiza una entrada del archivo existente.

Puede editar la lista resultante con un editor de texto normal. BackUP Master no carga las entradas existentes en el formulario.

*(N.B. Cuando BackUP Master guarda el puerto `22`, escribe un campo vacío. Una copia por lotes utiliza para esa entrada el valor `SshPort` de la configuración del script. Los puertos no estándar se escriben explícitamente.)*

<br />

## Formato del archivo

Escriba cada dispositivo en una línea independiente. Separe los campos con un **carácter TAB**, no con espacios. Los campos aparecen en el orden siguiente:

| Posición | Campo | Propósito |
|---|---|---|
| 1 | Nombre | Nombre del dispositivo; requerido |
| 2 | Dirección | Dirección IP o nombre DNS del dispositivo; requerido |
| 3 | Usuario | Usuario del dispositivo RouterOS; si se omite, se hereda de `Login` en `option.cfg` |
| 4 | Contraseña | Contraseña del dispositivo RouterOS; si se omite, se hereda de `Password` en `option.cfg` |
| 5 | Puerto | Puerto SSH de `1` a `65535`; si se omite, se hereda de `SshPort`, cuyo valor predeterminado es `22` |
| 6 | Marcador de dispositivo | `MikroTik`; puede estar vacío. No distingue entre mayúsculas y minúsculas |

Los campos a partir del séptimo no se utilizan. Se omiten las entradas con un marcador de dispositivo diferente.

### Lista de ejemplos

Los campos de este ejemplo están separados por caracteres TAB reales:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

El puerto se ha omitido en la segunda línea: aparecen dos caracteres TAB entre la contraseña y `MikroTik`. Sustituya las direcciones y credenciales por las suyas.

### Acceso compartido, contraseña y puerto

Si todos los dispositivos utilizan las mismas credenciales, especifíquelas una sola vez en `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Entonces `devicelist.cfg` solo necesita el nombre y la dirección de cada dispositivo:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Las credenciales especificadas en la entrada de un dispositivo anulan los valores compartidos.

*(N.B. El archivo de la lista de dispositivos contiene contraseñas. Restrinja el acceso tal como se describe en [SECURITY.md](SECURITY.md).)*

<br />

## Cómo se lee la lista

Se ignoran las líneas en blanco y aquellas cuyo primer carácter distinto de un espacio sea `#`. Escriba los comentarios en líneas independientes; un `#` dentro de un campo forma parte de su valor.

Los espacios iniciales y finales se eliminan del nombre, la dirección, el puerto y el marcador. El usuario y la contraseña se leen literalmente, incluidos los espacios y las comillas. Se admiten archivos con finales de línea de Windows (CRLF).

Si una línea —es decir, una entrada de dispositivo— incumple la sintaxis requerida, el script la omite durante la ejecución y emite una advertencia indicando que la entrada no es válida.

Si una línea está duplicada por cualquier motivo —es decir, coinciden los cuatro parámetros de conexión (**dirección, usuario, contraseña y puerto**)—, el script solo se conecta una vez a ese dispositivo y utiliza los datos de la última entrada.
Si conexiones diferentes tienen el mismo nombre, se utiliza la primera entrada válida y se omite la entrada en conflicto.

<br />

<a id="device-names"></a>
## Nombres de los dispositivos

El nombre se utiliza en los nombres de los archivos de copia de seguridad y, en el modo por lotes, en el subdirectorio del dispositivo.
El ajuste `UseIdentityName` en `option.cfg` determina de dónde viene el nombre:

| Valor | Fuente de nombre |
|---|---|
| `true` (valor predeterminado) | El valor de identidad del propio dispositivo RouterOS |
| `false` | El nombre de `devicelist.cfg`, el campo de BackUP Master o `--device-name` en una ejecución de un solo dispositivo mediante la CLI |

### Nombre entre paréntesis

Si el nombre original contiene paréntesis, el script utiliza el contenido del primer grupo completo, no vacío. Si no hay tal grupo, utiliza todo el nombre.

| Nombre original | Nombre de la copia de seguridad |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Caracteres permitidos

El nombre final conserva las letras —incluidas las cirílicas—, los dígitos, los puntos, los guiones y los guiones bajos. Los espacios y caracteres no válidos se sustituyen por `_`. Se eliminan los guiones bajos repetidos, iniciales o finales, así como los puntos iniciales y finales.

Por ejemplo, `ЦОД Москва №1` se convierte en `ЦОД_Москва_1`.

El nombre final debe tener **entre 1 y 32 caracteres**. Los nombres demasiado largos no se truncan: producen un error. No se admiten los nombres reservados `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` y `LPT1`–`LPT9`.

Los nombres finales deben ser únicos sin distinguir entre mayúsculas y minúsculas: `Router-A` y `router-a` se consideran iguales. El segundo dispositivo con ese nombre se omite durante la ejecución actual.

*(N.B. Cambiar el nombre final también cambia el subdirectorio del dispositivo. Las copias de seguridad antiguas no se mueven automáticamente.)*

<br />

## Importación desde Oxidized

Si ya mantiene una lista de dispositivos en Oxidized, el script puede obtenerla de allí. Añada lo siguiente a `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Defina `OxidizedHome` como el directorio que contiene `config` y `router.db`. El script genera `devicelist.cfg` a partir de ellos. No modifica los archivos de Oxidized.

*(N.B. La importación sustituye `devicelist.cfg`; no amplía el archivo. Las adiciones manuales se pierden la próxima vez que una actualización desde Oxidized termine correctamente.)*

### Configuración de la fuente

La configuración de Oxidized debe utilizar la fuente `csv` con un delimitador de un solo carácter. `source.csv.map` determina el orden de las columnas, con numeración a partir de cero:

| Mapa del campo | Valor utilizado |
|---|---|
| `name` | Nombre del dispositivo; columna requerida |
| `ip` | Dirección del dispositivo; si se omite, se utiliza el valor `name` |
| `username` | Usuario; si se omite, se utiliza el `Login` compartido de `option.cfg` |
| `password` | Contraseña; si se omite, se utiliza el `Password` compartido de `option.cfg` |
| `port` | Puerto SSH; si se omite, se utiliza `SshPort` |
| `model` | Modelo de dispositivo; si la columna está ausente, el parámetro raíz `model` se utiliza |

Las reglas `model_map` se aplican hasta la primera coincidencia. Solo se importan los dispositivos cuyo modelo final sea `routeros`. Si existe la columna `model`, el parámetro raíz no sustituye sus valores vacíos.

Los datos siempre se leen de `<OxidizedHome>/router.db`. El parámetro `source.csv.file` de Oxidized no cambia esta ruta.

### Si la importación falla

Si los archivos de Oxidized no están disponibles, su formato no es compatible o no se encuentran dispositivos adecuados, se conserva el `devicelist.cfg` anterior.

Con `IgnoreOxiAccess=true`, el script puede utilizar la lista válida anterior. Con `false`, no se realiza ninguna copia de seguridad a partir de la lista antigua.

Un error de importación afecta al resultado de la ejecución, aunque el procesamiento de copias de seguridad con la lista anterior termine correctamente.

Consulte [Solución de problemas](TROUBLESHOOTING.md) para obtener más información sobre los errores de la lista y de importación.
