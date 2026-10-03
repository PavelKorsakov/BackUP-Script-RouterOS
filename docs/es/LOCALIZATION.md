# Localización

[Índice](../README_ES.md)

## Idioma de la interfaz y los registros

El ruso (`ru`) y el inglés (`en`) están integrados en el script. No necesitan archivos de traducción independientes. La versión 2.3.1 incluye las traducciones externas de la interfaz y los registros `de.lang`, `es.lang`, `lv.lang`, `pl.lang` y `uk.lang`.

El idioma de la documentación y la disponibilidad de una traducción externa en tiempo de ejecución son independientes. Por eso puede existir documentación en un idioma aunque la distribución no incluya el archivo `.lang` correspondiente.

El idioma seleccionado se utiliza en menús, ayuda, mensajes de script y entradas de registro. No hay un ajuste de idioma separado para los registros.

<br />

## Elegir un idioma

El ajuste `Language` en `option.cfg` controla la selección. Su valor predeterminado es `auto`:

| Valor | Idioma utilizado |
|---|---|
| `auto` | Determinado por la configuración regional del sistema operativo |
| `ru` | Ruso incorporado |
| `en` | Inglés incorporado |
| Otro código de dos letras, como `de` | Traducción del archivo correspondiente, como `de.lang` |

Para seleccionar el ruso de forma permanente, defina lo siguiente en `option.cfg`:

```ini
Language=ru
```

Para una sola ejecución, puede seleccionar el idioma a través de la CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

La opción `--language` tiene precedencia sobre el ajuste del archivo de opciones, pero no modifica el propio archivo. Utilice `auto` o un código de dos letras; no se distingue entre mayúsculas y minúsculas.

### Selección automática

Con `auto`, el script toma el primer valor no vacío de `LC_ALL`, `LC_MESSAGES` y `LANG`, en ese orden.

Por ejemplo, `ru_RU.UTF-8` selecciona ruso, mientras `de_DE.UTF-8` selecciona la traducción alemana de `de.lang`. El inglés se utiliza para `C`, `C.UTF-8`, `POSIX`, o cuando el idioma no puede ser determinado.

Los mensajes también permanecen en inglés si la traducción externa seleccionada no está disponible.

<br />

## Instalación de una traducción externa

El directorio `lang/` contiene las traducciones externas disponibles `de.lang`, `es.lang`, `lv.lang`, `pl.lang` y `uk.lang`, además de la plantilla canónica `en.lang`. Para usar una traducción externa, copie el archivo necesario al directorio que contiene `mikrotik-backup.sh`.

Por ejemplo, ejecute esto en el directorio del script para instalar alemán:

```bash
cp -- lang/de.lang de.lang
```

Luego seleccione `de` en la configuración o especifíquelo cuando inicie el script:

```bash
mikrotik-backup.sh --language=de --help
```

El nombre del archivo consta de dos letras latinas y la extensión `.lang` —por ejemplo, `de.lang`—. Debe ser un archivo normal y legible, no un enlace simbólico.

*(N.B. El directorio `lang/` contiene la colección de traducciones. El script no las carga automáticamente desde allí: el archivo necesario debe colocarse junto al propio script.)*

`en.lang` contiene las 245 claves de la versión 2.3.1 y es la plantilla canónica para crear traducciones de terceros. No sustituye al inglés integrado ni participa como idioma externo en tiempo de ejecución. Un archivo `ru.lang`, si se crea, tampoco sustituye al ruso integrado y se ignora.

<br />

## Elegir un idioma en el Editor de configuración

Abra el editor con:

```bash
mikrotik-backup.sh -e
```

Vaya a la fila del idioma → pulse **Enter** hasta que aparezca el valor deseado → elija «Guardar».

Las opciones se recorren en este orden:

```text
auto → ru → en → idiomas externos detectados en orden alfabético → auto
```

El idioma del formulario cambia inmediatamente. Hasta que guarde, solo es una vista previa; «Cancelar» restaura el idioma anterior de la interfaz. Si `--language` se especificó al inicio, esa opción de la CLI vuelve a entrar en vigor después de salir del editor.

Los comentarios de `option.cfg` usan el idioma seleccionado por el propio ajuste `Language`, no una opción temporal de la CLI. Con `auto`, también se usa para ellos la configuración regional del sistema operativo.

Para más sobre el editor, vea [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Creación y edición de una traducción

Si la traducción que necesita aún no existe, puede prepararla usted mismo. Tome `lang/en.lang` de la misma versión del script y guarde una copia como `<xx>.lang`, donde `xx` es el código de dos letras del nuevo idioma. La plantilla de la versión 2.3.1 contiene las 245 claves.

El formato es simple: cada mensaje tiene su propia línea. Por ejemplo, la plantilla inglesa contiene:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Cada clave comienza por `msg_`, seguido del nombre del mensaje (`version`, `menu_title`) y del sufijo de idioma `_en`.

Para un idioma nuevo, sustituya el sufijo `_en` por `_xx` en todas las claves y traduzca solo los valores entre comillas. No cambie los nombres de los mensajes y conserve exactamente todos los placeholders. Para corregir una traducción existente, basta con modificar el texto necesario a la derecha de `=`.

No es necesario traducir todo el archivo de una vez: los mensajes que falten se mostrarán en inglés. El script no utiliza claves nuevas arbitrarias.

### Reglas de formato de archivo

Guarde el archivo como UTF-8. Encierre cada valor entre comillas dobles y no utilice escapes innecesarios. No añada espacios antes de una clave, alrededor de `=` ni después de la comilla de cierre.

Utilice `\"` para incluir una comilla doble en el texto y `\\` para una barra inversa. No se admiten otras secuencias de escape, incluidas `\n` y `\t`. Se permite un carácter `=` dentro de las comillas.

Las líneas en blanco se omiten. El formato `.lang` no admite comentarios; un `#` dentro de las comillas forma parte del texto. Los finales de línea de Windows (CRLF) y un BOM al principio del archivo son compatibles.

Las líneas mal formadas se omiten sin dejar de utilizar las demás traducciones válidas. Si un mensaje se especifica más de una vez, prevalece la última entrada válida. No se permiten caracteres de control ni códigos de color del terminal en las traducciones.

*(N.B. Un archivo de localización se trata como datos de texto. No se amplían las variables y los comandos de shell no se ejecutan desde él.)*

### Marcadores de posición en los mensajes

Algunas cadenas contienen valores entre llaves, por ejemplo:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Durante la ejecución, el script sustituye `{index}` y `{total}` por el número del dispositivo y el número total de dispositivos. No traduzca estos marcadores: conserve exactamente una vez cada marcador de posición de la cadena de origen. Puede cambiar su posición dentro de la frase.

Si los marcadores de posición no son válidos, se utiliza el mensaje en inglés en lugar de esa cadena.

Después de guardar el archivo, compruebe la traducción en la ayuda y en el menú interactivo con ese idioma seleccionado. Las causas por las que una traducción puede no cargarse se explican en [Solución de problemas](TROUBLESHOOTING.md#language-problems).
