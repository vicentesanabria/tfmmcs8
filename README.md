# tfmmcs8
Trabajo Fin de Master - Master Ciberseguridad VIII Ed.

El propósito del presente trabajo fin de master consiste en la configuración
de una distribución linux para la instalación de herramientas que sirvan en
tareas de obtención de información en fuentes abiertas (OSINT).

El listado de utilidades descritas en el presente documento han sido aportadas por
todos los participantes del master mediante una actividad colaborativa. Se agrupado
según el mecanismo de acceso y por su tipo (web, programas, extensiones
de navegador).

Para facilitar el proceso de instalación se ha generado un script en bash script
que las despliega. El script se ha hecho lo más genérico posible para que pueda
ser utilizado en las distribuciones basadas en APT. Dicho script ha sido probado
específicamente sobre la distribución Ubuntu 20.04, aunque podría también ser
ejecutado en distribuciones Debian.

----------------------------------------------------------------------------------

Instalación

git clone https://github.com/vicentesanabria/tfmmcs8.git
cd tfmmcs8
./osintn31mcs8.sh -h

----------------------------------------------------------------------------------

Uso de la herramienta

NOTA: No lanzar como usuario root ni sudoer. Si que se precisa que el usuario sea 
sudoer o tenga permisos de administrador. Si se precisan credenciales de administrador
se le solicitarán durante la ejecución del mismo.

$ osintn31mcs8.sh 

Uso: ./osintn31mcs8.sh [opcion]

Opciones:

	-h:  Ofrece esta ayuda
	
	-a: Instala todos los elementos (requisitos, marcadores y aplicaciones)
	
	-b: Instala los marcadores en Firefox
	
	-p: Instala las aplicaciones de escritorio
	
	-t: Instala los requisitos necesarios de las aplicaciones
	
