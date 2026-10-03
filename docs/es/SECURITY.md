# Seguridad

[Índice](../README_ES.md)

## Cuentas

El script no necesita privilegios de **root**. Un usuario normal solo necesita acceso a los archivos de configuración y permiso de escritura en el almacenamiento y los registros seleccionados.

La creación de un usuario dedicado **bsmt** y la configuración del script para ejecutarse con esa cuenta se explican en [INSTALL.md](INSTALL.md#ejecutar-el-script-automáticamente).

También es recomendable crear un usuario dedicado a las copias de seguridad en el dispositivo RouterOS y restringir su inicio de sesión a la dirección IP del host que ejecuta el script. Los permisos de esa cuenta deben permitir las operaciones seleccionadas: obtener la configuración, crear y descargar copias de seguridad, eliminar archivos temporales y realizar las tareas de limpieza habilitadas.

<br />

## Conexión a RouterOS

El script se conecta mediante SSH usando autenticación por contraseña. No utiliza claves SSH ni el agente. Los archivos se obtienen mediante el protocolo SCP heredado, es decir, con `scp -O`.

El script utiliza su propia configuración de conexión. No lee la configuración SSH del usuario ni la del sistema en `~/.ssh/config`, ya que el cliente se inicia con `-F /dev/null`. El agente y los reenvíos de X11 y de puertos están deshabilitados.

**¡Atención!!! La verificación de la clave del host del servidor está desactivada.**

El perfil actual utiliza estos ajustes:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Los archivos `known_hosts` habituales no se leen ni se modifican. Por tanto, el script no comprueba si el servidor que responde es el dispositivo esperado o un impostor. Téngalo en cuenta al organizar el acceso de red a los routers.

<br />

<a id="secrets"></a>
## Contraseñas al iniciar el script

Una contraseña proporcionada mediante `--password` o `-p=` pasa a formar parte del comando de ejecución. Puede quedar visible en los argumentos del proceso y guardarse en el historial del shell. Lo mismo ocurre con una contraseña de cifrado proporcionada mediante `--encrypt`.

### Introducir contraseñas mediante BackUP Master

Para evitar incluir la contraseña SSH en la línea de comandos, inicie BackUP Master:

```bash
mikrotik-backup.sh -b
```

Rellene las credenciales del dispositivo en el formulario y elija la acción necesaria. Ambas contraseñas se muestran como asteriscos, y los valores introducidos en el formulario no pasan al historial de comandos del shell.

Al conectarse, el propio script pasa la contraseña SSH a `sshpass` mediante un descriptor de archivo (`-d`), no mediante el argumento `sshpass -p` ni la variable de entorno `SSHPASS`.

### La contraseña de cifrado de `.backup`

La contraseña de cifrado se incluye en el comando de RouterOS que se entrega al proceso hijo `ssh`. Un usuario del host con permisos suficientes para inspeccionar los argumentos de los procesos puede verla mientras se crea una copia de seguridad binaria.

Introducir la contraseña mediante BackUP Master o almacenarla en `option.cfg` no cambia la forma en que se transmite. Cifrar el archivo no lo protege frente a un administrador del propio host de copias de seguridad.

### Copiar un comando de consola

La acción «3. Copiar el comando de consola» de BackUP Master envía al portapapeles un comando que contiene las credenciales de conexión y, si se ha definido para una copia binaria, la contraseña de cifrado.

Téngalo en cuenta al utilizar el historial del portapapeles y al pegar el comando en un shell. Que una contraseña aparezca como asteriscos en el formulario no significa que esté oculta en el comando copiado.

<br />

## Archivos que contienen datos sensibles

| Archivo | Lo que puede contener |
|---|---|
| `devicelist.cfg` | Direcciones de dispositivos, usuarios y contraseñas SSH en texto sin cifrar |
| `option.cfg` | Valores compartidos de `Login` y `Password`, y contraseña de cifrado `encrypt` |
| `.rsc` y `.backup` | Configuración de los dispositivos, contraseñas y otros datos sensibles |
| Archivo ZIP mensual | Las mismas copias de seguridad y registros reunidos en un archivo ZIP |

No coloque archivos de configuración de trabajo o copias de seguridad en un repositorio público o directorio accesible públicamente.

### Datos sensibles en archivos .rsc

De forma predeterminada, `show_sensitive=true`, por lo que los valores sensibles se incluyen en la exportación de texto. Para deshabilitarlos, defina lo siguiente en `option.cfg`:

```ini
show_sensitive=false
```

Incluso entonces, el archivo sigue siendo una configuración de su dispositivo: direcciones, estructura de red, comentarios y otras cadenas proporcionadas por el usuario no desaparecen de él.

### Cifrado de la copia de seguridad binaria

De forma predeterminada, `encrypt` está vacío y `.backup` se guarda sin cifrar. Para habilitar el cifrado, defina una contraseña en el archivo de opciones o en el campo correspondiente de BackUP Master:

```ini
encrypt=MySuperPassword
```

Se utiliza el algoritmo AES-SHA256. Cifra **únicamente `.backup`**; no cifra `.rsc`, `option.cfg`, la lista de dispositivos, los registros ni el propio ZIP. El acceso al archivo ZIP mensual debe restringirse con el mismo cuidado que el acceso a los archivos que contiene.

<br />

## Permisos de los archivos y del almacenamiento

El script se ejecuta con `umask 077`. Los directorios de almacenamiento local que crea reciben el modo `0700`; `option.cfg` y `devicelist.cfg` se escriben con el modo `0600` cuando se guardan desde el programa.

El propietario y los permisos de los directorios de almacenamiento creados por el administrador no se cambian automáticamente. Si prepara un directorio manualmente, debe configurar su acceso usted mismo.

El directorio local de archivado mensual, `archive/`, debe tener el modo `0700` y pertenecer al usuario que ejecuta el script. El requisito también se aplica a un directorio existente. Los archivos ZIP locales creados por el script tienen el modo `0600`.

En modo por lotes, cuando se usa almacenamiento de red verificado con `UseNetFolder=true`, el servidor NAS puede determinar los propietarios y permisos de los objetos archivados. Una diferencia respecto a los valores locales no impide por sí sola el archivado. Configure el acceso al almacenamiento de red mediante el sistema operativo y el NAS.

Ejemplos de preparación de directorios y acceso al usuario **bsmt** se proporcionan en [INSTALL.md](INSTALL.md).

*(N.B. El script lee como datos su configuración, la lista de dispositivos, las traducciones y cualquier configuración de Oxidized que utilice; no las ejecuta como scripts de shell.)*

<br />

## Cambios realizados en el dispositivo

De forma predeterminada, la caché DNS y el historial de consola de RouterOS se borran antes de crear una copia de seguridad binaria. Si no necesita estas acciones, desactívelas en `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Puede deshabilitar las mismas funciones mediante el Editor de configuración, BackUP Master o las opciones correspondientes de la CLI. Estas operaciones de limpieza no se realizan cuando solo se obtiene `.rsc`.

<br />

## Registros y uso compartido de información diagnóstica

El nivel detallado `LogLevel=3` añade información sobre las etapas de procesamiento; no registra contraseñas ni comandos de conexión completos.

Los diagnósticos SSH procesados ocultan los valores exactos conocidos de la dirección, el usuario, la contraseña SSH y la contraseña de cifrado. Esto no sanea el contenido de las copias de seguridad ni garantiza que se eliminen todos los secretos de un texto arbitrario.

Los archivos temporales que contienen diagnósticos no procesados pueden incluir datos sensibles. Se crean con modo `0600` y se eliminan durante la limpieza normal.

Antes de enviar a otras personas registros, capturas de pantalla o la salida de un comando, revise su contenido. El contenido completo de `devicelist.cfg`, una lista de procesos o el contenido del portapapeles pueden revelar datos que no aparecen en los registros normales.

Para obtener más información sobre las entradas de registro, consulte [LOGGING.md](LOGGING.md); para investigar errores, vea [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Ejecuciones simultáneas

Las ejecuciones del mismo usuario que emplean el mismo `BackupRoot` usan bloqueos:

| Ejecuciones simultáneas | ¿Qué pasa? |
|---|---|
| Una ejecución por lotes y otra ejecución por lotes o de un solo dispositivo | La segunda ejecución no adquiere el bloqueo |
| Dos ejecuciones de un solo dispositivo para el mismo dispositivo | La segunda ejecución no adquiere el bloqueo |
| Ejecuciones de un solo dispositivo para dispositivos diferentes | Pueden ejecutarse simultáneamente |

Si el bloqueo está ocupado, el script sale con el código `32`. Las raíces de almacenamiento diferentes no se coordinan como una sola área cuando una está anidada dentro de otra.

Los archivos de bloqueo se guardan en `/tmp/mikrotik-backup-${UID}/` y permanecen después de que el script termine. Su mera presencia no significa que el script siga en ejecución.

**No borre estos archivos para «eliminar un bloqueo obsoleto».** El bloqueo está asociado a un descriptor de archivo abierto por el proceso, no a la mera existencia del archivo. Estos bloqueos tampoco protegen los datos frente a otros programas que los modifiquen directamente.

<br />

## Pruebas de restauración

Verificar la suma de comprobación del script y obtener correctamente un archivo de copia de seguridad no sustituye a las pruebas de restauración.

El propio script no restaura RouterOS. Debe comprobar por separado que las copias de seguridad puedan utilizarse en un dispositivo adecuado y decidir durante cuánto tiempo conservarlas. Para obtener más información, consulte [BACKUPS.md](BACKUPS.md).
