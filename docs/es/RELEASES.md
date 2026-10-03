# Versiones

[Índice](../README_ES.md)

## Versión 2.3.1

**Una versión de mantenimiento y hotfix posterior a la versión 2.3.0 publicada.**

La arquitectura de un solo archivo y el requisito mínimo de GNU Bash 4.4 no cambian. `UseIncremental` es ahora un ajuste booleano canónico: `false` omite la comparación posterior a la copia y la etapa de retención incremental, y conserva cada artefacto nuevo creado y validado correctamente. No tiene una opción de CLI específica.

Se ha corregido el orden de calendario del archivado mensual y se ha reforzado el tratamiento de metadatos para el almacenamiento de red que cumple los requisitos, mientras se mantienen las comprobaciones estrictas de metadatos en sistemas de archivos locales. El Editor de configuración y BackUP Master utilizan ahora un área de visualización aceptada en terminales de menor altura, sin exigir que todas las filas del formulario quepan a la vez.

El ruso y el inglés siguen integrados. La versión 2.3.1 incluye traducciones externas de runtime para alemán, español, letón, polaco y ucraniano (`de`, `es`, `lv`, `pl`, `uk`), además de `en.lang` como plantilla de traducción canónica completa con 245 claves. La documentación de usuario está disponible en 11 idiomas.

Las notificaciones siguen sin estar implementadas y quedan fuera del alcance de esta versión.

<br />

Consulte [INSTALL.md](INSTALL.md) para obtener instrucciones sobre la descarga de los archivos, la verificación de las sumas de comprobación y la preparación del script.
