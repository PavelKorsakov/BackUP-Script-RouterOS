# Interfaz interactiva

[Índice](../README_ES.md)

## Menú principal

El menú principal permite configurar el script, crear copias de seguridad, preparar una lista de dispositivos o abrir la ayuda integrada. Para abrirlo, ejecute:

```bash
mikrotik-backup.sh -i
```

| Elemento | Qué abre o ejecuta |
|---|---|
| `1` | BackUP Master para trabajar con un solo dispositivo |
| `2` | Copia de seguridad por lotes mediante la lista de dispositivos |
| `3` | Editor de configuración para crear o cambiar `option.cfg` |
| `4` | Referencia de opciones de la CLI |
| `5` | Instrucciones para usar el script |
| `6` | Salir a la consola |

El elemento `2` aparece cuando `devicelist.cfg` contiene al menos una entrada admisible. Si la lista todavía no existe o no contiene dispositivos adecuados, el elemento permanece oculto. Los números de los demás elementos no cambian.

Después de una copia de seguridad por lotes, se muestra el resultado y el script vuelve a la consola.

*(N.B. Ejecutar el script sin opciones no abre el menú principal. Si falta `option.cfg` o no contiene ajustes utilizables, se abre el Editor de configuración; si los ajustes ya están preparados, el script inicia la copia de seguridad por lotes.)*

<br />

## Controles

Desplácese por los elementos con las teclas **Up** y **Down**, y seleccione uno con **Enter**. Si una acción tiene un número asociado, también puede elegirla mediante la tecla numérica correspondiente.

En el editor y en BackUP Master aparece una descripción del campo seleccionado encima de la lista. Si no caben todas las filas en la ventana del terminal, la lista se desplaza al utilizar las teclas de flecha. El encabezado y la descripción siguen visibles, y la fila seleccionada permanece dentro de la ventana.

Las acciones de guardar, ejecutar y salir se encuentran al final de la misma lista. Las filas ocultas no están disponibles con los ajustes seleccionados y se omiten durante la navegación.

Se requieren un terminal y la utilidad `stty`. Tanto la entrada estándar como la salida estándar deben estar conectadas a un terminal. Las pantallas principales requieren al menos 46 columnas de ancho; las instrucciones integradas requieren 80. Si la ventana es demasiado pequeña, el script informa del error `31`; amplíe la ventana y vuelva a ejecutarlo.

<br />

## Editor de configuración

Abra el editor a través del elemento `3` en el menú principal o directamente con:

```bash
mikrotik-backup.sh -e
```

Si `option.cfg` ya está preparado, el formulario está rellenado con su configuración. Si el archivo aún no existe, se utilizan valores predeterminados.

El editor permite elegir el idioma, el origen de la lista de dispositivos y los ajustes de copia de seguridad, almacenamiento, archivado mensual y registro. Los ajustes y sus valores admitidos se describen en [OPTIONS.md](OPTIONS.md).

### Modificar la configuración

Cambie los selectores Sí/No, el tipo de copia de seguridad, el formato de exportación y el nivel de registro pulsando **Enter** en la fila correspondiente. Al seleccionar una ruta o el día del archivado mensual se abre un campo para introducir el valor.

El campo «Usar copias de seguridad incrementales» (`UseIncremental`) aparece inmediatamente después del tipo de copia de seguridad. «Sí» habilita la comparación; «No» conserva cada nueva copia válida sin compararla con la anterior.

Para el archivado mensual, introduzca `false` para deshabilitarlo o un número del `1` al `28`. El formulario muestra el estado deshabilitado como «No» y, cuando está habilitado, el día seleccionado del mes.

Los campos que no se aplican al modo elegido quedan deshabilitados. Por ejemplo, cuando solo se selecciona `.rsc`, no están disponibles el cifrado de la copia binaria ni las operaciones de limpieza que la preceden; cuando solo se selecciona `.backup`, no están disponibles los ajustes de exportación de texto. Al cambiar de modo, los ajustes que dejan de ser aplicables recuperan sus valores predeterminados.

La contraseña de cifrado se introduce y se muestra como asteriscos.

### Guardado y cancelación

Elija los ajustes necesarios → vaya a «Guardar» → pulse **Enter**. Los ajustes seleccionados se utilizan para crear o sobrescribir `option.cfg`.

Hasta que guarde, los cambios solo existen en memoria. «Cancelar» deja intacto el archivo existente. Si ha cambiado algo, el editor le pide que confirme que desea descartar los cambios.

Si abrió el editor desde el menú principal, volverá a él. Si ejecutó el editor por separado con `-e`, al cerrarlo regresará a la consola.

*(N.B. `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` y `Password` no se muestran en el formulario. Sus ajustes y reglas de conservación se explican en [OPTIONS.md](OPTIONS.md).)*

### Elegir un idioma

En la fila de idiomas, cada pulsación de **Enter** selecciona la siguiente opción:

```text
auto → ru → en → idiomas externos detectados en orden alfabético → auto
```

El idioma del formulario cambia de inmediato para que pueda previsualizarlo. «Guardar» escribe el idioma seleccionado en `option.cfg`; «Cancelar» restaura el idioma anterior de la interfaz. Si se proporcionó explícitamente `--language` al iniciar el script, esa opción vuelve a tener efecto al salir del editor.

La instalación de traducciones externas se describe en [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master permite rellenar los parámetros de un dispositivo, crear sus copias de seguridad, guardar el dispositivo en la lista o preparar un comando para ejecutarlo desde la consola.

Elija el elemento `1` del menú principal o ejecute:

```bash
mikrotik-backup.sh -b
```

A diferencia del Editor de configuración, BackUP Master no rellena sus campos normales desde `option.cfg`. Sus valores proceden de los valores predeterminados integrados y de las opciones pasadas expresamente mediante la CLI. `UseIncremental` es la excepción: toma su valor del archivo de opciones o usa `true` cuando el ajuste está ausente.

Las entradas existentes de `devicelist.cfg` tampoco se cargan en el formulario. Debe rellenar el nombre, la dirección, el usuario y la contraseña del dispositivo elegido.

### Campos de BackUP Master

Los campos aparecen en el siguiente orden. Se muestran sus nombres tal como aparecen en la interfaz en español:

| Campo | Propósito |
|---|---|
| Nombre del dispositivo | Nombre utilizado en la lista y en las copias cuando está deshabilitada la obtención de la identidad de RouterOS |
| Dirección IP | Dirección IP o nombre DNS del dispositivo |
| Usuario | Usuario del dispositivo RouterOS |
| Contraseña | Contraseña del dispositivo RouterOS |
| Puerto SSH | Puerto de conexión; `22` de forma predeterminada |
| Tipo de copia de seguridad | Configuración `.rsc`, copia binaria `.backup` o ambos formatos |
| Usar copias de seguridad incrementales | Comparar una nueva copia de seguridad con la anterior o conservarla sin comparar |
| Formato de exportación | `compact`, `terse` o `verbose` |
| Datos sensibles | Incluir valores sensibles en la exportación de texto |
| Contraseña de cifrado | Cifrar la copia de seguridad binaria; un valor vacío deshabilita el cifrado |
| Borrar la caché DNS | Limpiar la caché DNS antes de crear una copia de seguridad binaria |
| Borrar el historial de consola | Limpiar el historial de la consola antes de crear una copia de seguridad binaria |
| Directorio de copias de seguridad | Directorio en el que se guardan los archivos |
| Este es un directorio de red | Valor de `UseNetFolder`; la comprobación del montaje se aplica en el modo por lotes |
| Usar la identidad de RouterOS | Obtener el nombre del dispositivo en lugar de utilizar el nombre introducido en el formulario |

Los selectores, el tipo de copia y el formato de exportación se cambian con **Enter**; los demás valores se introducen en sus campos. Ambas contraseñas se ocultan con asteriscos.

**¡Atención!!!**
La inclusión de datos sensibles en la exportación de texto, el borrado de la caché DNS y el borrado del historial de consola antes de una copia binaria están activados de forma predeterminada. Elija la configuración que necesita antes de ejecutar la copia de seguridad.

BackUP Master no tiene campos para `MonthlyArchive`, `LogLevel` ni `MainLogPath`. El archivado mensual queda deshabilitado cuando se ejecuta una copia mediante BackUP Master; los ajustes de registro proceden de `option.cfg` y de las opciones de la CLI proporcionadas para la ejecución.

### 1. Ejecutar la copia de seguridad

Rellene la dirección, el usuario y la contraseña; revise el puerto y los ajustes de copia de seguridad → seleccione «1. Ejecutar la copia de seguridad».

Cuando está activada la obtención de la identidad de RouterOS, el nombre de la copia se toma del dispositivo. Cuando está desactivada, debe rellenar el campo «Nombre del dispositivo».

Al terminar se muestran el resultado y su código, y el script vuelve a la consola. No regresa al formulario principal, tanto si la copia de seguridad finaliza correctamente como si falla.

Las ubicaciones de los archivos y las reglas de retención se describen en [BACKUPS.md](BACKUPS.md); los mensajes de progreso se explican en [LOGGING.md](LOGGING.md).

### 2. Guardar el dispositivo en `devicelist.cfg`

Para guardar se necesitan el nombre, la dirección, el usuario, la contraseña y el puerto SSH del dispositivo. Hasta que se rellenen todos los campos obligatorios, la acción correspondiente permanecerá deshabilitada.

BackUP Master crea el archivo, añade una entrada nueva o actualiza una entrada existente con el mismo nombre. Si las entradas entran en conflicto o falla el guardado, la lista anterior permanece intacta. El formulario sigue abierto después de guardar.

**Solo los datos del dispositivo se guardan en `devicelist.cfg`.** Los ajustes de copia de seguridad del formulario no se escriben en `option.cfg`, y esta acción no inicia una copia de seguridad.

*(N.B. El puerto `22` se guarda como un campo vacío. En una ejecución posterior por lotes, esa entrada utiliza `SshPort` de la configuración del script. Los puertos no estándar se escriben explícitamente.)*

Las reglas de formato y actualización de la lista se describen en [DEVICES.md](DEVICES.md).

### 3. Copiar el comando de consola

BackUP Master construye un comando de inicio desde el formulario completado y lo envía al portapapeles. No se inicia ninguna copia de seguridad, y el BackUP Master termina volviendo a la consola.

Esta función requiere GNU `base64` compatible con `--wrap=0` y un terminal que admita OSC 52. Si trabaja a través de un multiplexor de terminal, este también debe retransmitir el comando. Si el terminal no admite la transferencia al portapapeles, el comando no se muestra en texto claro en la pantalla.

Los parámetros que coinciden con los valores integrados pueden omitirse del comando. Cuando lo ejecute más adelante, los ajustes de `option.cfg` seguirán aplicándose, por lo que el resultado puede diferir del obtenido al ejecutar la copia directamente mediante BackUP Master.

El ajuste `UseIncremental` no está incluido en el comando: no tiene opción CLI dedicada. Cuando se ejecuta el comando copiado, el valor viene de `option.cfg` o de los valores predeterminados.

*(N.B. El comando colocado en el portapapeles contiene contraseñas. Téngalo en cuenta al usar el historial del portapapeles y al pegar el comando en un shell. Para obtener más información, consulte [SECURITY.md](SECURITY.md).)*

### 0. Volver al menú principal

El resultado depende de cómo haya abierto BackUP Master:

| Cómo se abrió | Destino al volver |
|---|---|
| Del menú principal con `-i` | Menú principal |
| Como una ejecución separada con `-b` | Consola |

Los valores del formulario que no se hayan guardado se descartan. Una entrada ya guardada en `devicelist.cfg` permanece allí.

<br />

## Ayuda e instrucciones

El elemento `4` del menú principal abre la referencia de opciones de la línea de comandos, mientras que el elemento `5` muestra unas instrucciones breves para utilizar el script.

Si el texto no cabe verticalmente, se divide en páginas. Desplácese por ellas con **PageUp / PageDown**; el número de la página actual se muestra en pantalla.

El elemento `0` vuelve al menú principal y el elemento `6` sale del script. Puede seleccionar estas acciones con las teclas de flecha y **Enter**, o mediante la tecla numérica correspondiente.

La misma ayuda de la CLI está disponible directamente desde la consola:

```bash
mikrotik-backup.sh -h
```
