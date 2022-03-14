#!/bin/bash
############################################################################
##                    ****** osintn31mcs8.sh ******                       ##
## Script para la instalación de software para desarrollar prácticas      ##
## de búsqueda en fuentes abiertas (OSINT)                                ##
##                                                                        ##
## Master Ciberseguridad VIII edición                                     ##
## UCAM - ElevenPath                                                      ##
## TFM 3.1 Distribución orientada a la obtención de información en la red ##
##                                                                        ##
## Autor: Vicente Sanabria                                                ##
## Fecha: Marzo 2022                                                      ##
## Tutores: Yaiza Rubio/Felix Brezo                                       ##
############################################################################

# Tipografia
blue="\e[0;34m\033[1m"
cyan="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"
green="\e[0;32m\033[1m"
red="\e[0;31m\033[1m"
yellow="\e[0;33m\033[1m"
end="\033[0m\e[0m"
blink="\e[5m"
endblink="\e[25m"

# Función que instala los marcadores OSINT en Firefox. 
# Este debe haber sido iniciado en algún momento y 
# permanecer cerrado durante la importación
function marcadores () {
	# Se utiliza una copia de seguridad SQLite3 con los marcadores
	echo -e "${blue}[*]${end}${gray} Marcadores en Firefox: \n${end}"

	# Se comprueba que firefox no se está ejecutando
	/usr/bin/killall -0 firefox > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then
		# Se comprueba que existe perfil de firefox en la carpeta home del usuario
		if [ -d ~/.mozilla/firefox ]; then
			# Se comprueba que está el fichero con la copia de los marcadores
			if [ -s marcadores.osint.mcs8ed.dump.sqlite ]; then
				# Se comprueba que está instalado SQLite3
				if [ -s /usr/bin/sqlite3 ]; then
					echo -e "${red}[!]${end}${yellow} Se ha detectado que posee marcadores en Firefox. Si continua se sobreescribirán.\n${end}" 
					read -p "¿Desea continuar (S/n)? " choice
					choice=${choice,,,,,}
					if [[ $choice =~ ^(si|s|S|Si|SI| ) ]] || [[ -z $choice ]]; then
						echo -ne "\n${cyan}[+]${end}${gray} Importando marcadores ................. ${end}"
						sqlite3 ~/.mozilla/firefox/*default-release/places.sqlite ".restore marcadores.osint.mcs8ed.dump.sqlite"
						checkfin
						echo
					else
						echo -e "\n${cyan}[+]${end}${gray} Ejecute de nuevo el script más adelante para desplegar los marcadores. \n${end}"
					fi
				else
					echo -e "${red}[!] ERROR:${end}${yellow} SQLite3 no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
				fi
			else
				echo -e "${red}[!] ERROR:${end}${yellow} El fichero de marcadores no existe. Asegúrese que está en la ruta indicada. \n${end}"
			fi
		else
			echo -e "${red}[!] ERROR:${end}${yellow} Firefox no se ha ejecutado todavía. Ejecútelo y vuelva a lanzar la instalación. \n${end}"	
		fi
	else
		echo -e "${red}[!] ERROR:${end}${yellow} Firefox se está ejecutando ${end}"
		echo -e "[*] Ciérrelo e inténtelo de nuevo \n"
	fi
}

# Función que instala los requisitos necesarios para 
# la implementación del resto de herramientas
function requisitos () {
	DEPS="git python3 python3-venv libreadline-dev mongodb pdfgrep default-jre sqlite3 tor google-chrome-stable"

	# Dependencias para instalar Google Chrome - Necesiario para GHunt y SocialPwned
	echo -ne "${blue}[*]${end}${gray} Añadiendo repositorio de Google Chrome .......... ${end}"
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - > /dev/null 2>&1
	sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' > /dev/null 2>&1
	checkfin
	echo
	echo -e "${blue}[*]${end}${gray} Actualizando repositorios (apt update): ${end}"
	sudo apt update > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Ocurrió un error actualizando los repositorios APT. Revíselo y vuelva a intentarlo.\n${end}"
		exit 2
	else
		echo -e "${cyan}\n[+]${end}${gray} Repositorio APT actualizado con éxito \n${end}"
	fi
	sleep 3

	# Se construye una lista con los paquetes necesarios
	echo -e "${blue}[*]${end}${gray} Comprobando paquetes necesarios ...... ${end}"
	INSTALAR=""
	for paquete in $DEPS; do
		dpkg -s $paquete &> /dev/null
		if [ "$(echo $?)" == "0" ]; then
			echo -e "\t${green}[V]${end}${gray} $paquete ${end}"
		else
			echo -e "\t${red}[X]${end}${gray} $paquete ${end}"
			INSTALAR="$INSTALAR $paquete"
		fi
	done

	if [[ "$INSTALAR" != "" ]]; then
		#Se instalan los paquetes pendientes
		echo -e "\n${blue}[*]${end}${gray} Instalando paquetes pendientes ...... ${end}"
		for paq in $INSTALAR; do
			sudo apt install $paq -y > /dev/null 2>&1
			if [ "$(echo $?)" != "0" ]; then
				echo -e "\t${red}[X]${end}${gray} $paq ${end}"
				echo -e "${red}\n[!] ERROR:${end}${yellow} Ocurrió un error instalando las dependencia. Revíselo y vuelva a intentarlo.${end}"
				echo -e "\t${yellow}Si decide ignorar esta advertencia, quizá falle la instalación o ejecución de las herramientas OSINT.\n${end}"
			else
				echo -e "${green}\n[+]${end}${gray} $paq Instalado con éxito${end}"
			fi
			sleep 1
		done
	else
		echo -e "${cyan}\n[+]${end}${gray} Requisitos instalados con éxito \n${end}"
	fi
}

function checkfin () {
	if [ "$(echo $?)" == "0" ]; then
			echo -e "[${green}V${end}]"
		else
			echo -e "[${red}X${end}]"
	fi
}

# Función que prepara el entorno para la descarga de 
# repositorios GIT
function entorno_git () {
	echo -ne "${blue}[*]${end}${gray} Entorno para alojar los repositorios GIT ................. ${end}"
	# Se crea la carpeta para alojar los repositorios
	if [ ! -d $path_actual/git ]; then
		mkdir $path_actual/git > /dev/null 2>&1
		checkfin
	else
		for repo in $repositorios; do
			repotmp="$(echo $repo | awk -F '/' '{print $NF}')"
			if [ -d $path_actual/git/$repotmp ]; then
				echo -e "\n\n${red}[!]${end}${yellow} Se ha detectado que posee una carpeta de la herramienta $repotmp.\n${end}"
				echo -e "${red}[!]${end}${yellow} Si continua, podrían sobreescribirse ficheros de configuración que haya podido modificar.\n${end}"
				read -p "¿Desea continuar (s/N)? " choice
				choice=${choice,,,,}
				if [[ $choice =~ ^(si|s|S|Si|SI) ]]; then
					echo -ne "${yellow}[!]${end}${gray} Carpeta del repositorio $repotmp eliminada ..... ${end}"
					rm -rf $path_actual/git/$repotmp > /dev/null 2>&1
					checkfin
				else
					continue
				fi
			fi
		done
		# Si la carpeta ya existía, se borra su contenido
	#	rm -rf $path_actual/git/* > /dev/null 2>&1
	fi
	githome="$path_actual/git"

	# Se comprueba si está el paquete git instalado
	if [ ! -s /usr/bin/git ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Git no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi
}

# Función que clona los proyectos declarados en la variable $repositorios
function clonar_proyectos () {
	echo -e "${blue}[*]${end}${gray} Clonando repositorios: \n${end}"
	for repositorio in $repositorios; do
		repotemp="$(echo $repositorio | awk -F '/' '{print $NF}')"
		if [ ! -d $githome/$repotemp ]; then
			echo -ne "${cyan}[+]${end}${gray} Respositorio  $repotemp ............. ${end}"
			git clone https://github.com/$repositorio $githome/$repotemp > /dev/null 2>&1
			checkfin
			sleep 2
		fi
	done

	dpkg -s maltego > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then 
		echo -ne "${cyan}[+]${end}${gray} Respositorio  Maltego ............. ${end}"
		mkdir $githome/maltego > /dev/null 2>&1
		wget -O $githome/maltego/$vermaltego https://maltego-downloads.s3.us-east-2.amazonaws.com/linux/$vermaltego > /dev/null 2>&1
		checkfin
	fi
	echo
}

function theHarvester () {
	echo -ne "${cyan}[+]${end}${gray} Instalando theHarvester ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/theHarvester ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de theHarvester no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/theHarvester
	pip install -r requirements/base.txt > /dev/null 2>&1
	# Error encontrado al instalar que se solventa volviendo a ejecutar pip install
	if [ "$(echo $?)" != "0" ]; then
		pip install -r requirements/base.txt > /dev/null 2>&1
	fi
	checkfin

	echo -e "\n\t${blue} ** theHarvester **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/theHarvester/ ${end}"
	echo -e "\t${cyan} > python3 theHarvester.py -h${end}\n"
}

function dmitry () {
	dpkg -s maltego > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then	
		echo -ne "${cyan}[+]${end}${gray} Instalando dmitry ................. ${end}"
		sudo apt install dmitry -y > /dev/null 2>&1
		checkfin
	else
		echo -ne "${cyan}[+]${end}${gray} Dmitry ya instalado................. ${end}"
		echo -e "[${yellow}!${end}]"
	fi
	echo -e "\n\t${blue} ** dmitry **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > dmitry ${end}\n"
}

function recon-ng () {
	echo -ne "${cyan}[+]${end}${gray} Instalando recon-ng ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/recon-ng ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de recon-ng no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/recon-ng
	pip install -r REQUIREMENTS > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** recon-ng **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/recon-ng/ ${end}"
	echo -e "\t${cyan} > ./recon-ng${end}\n"
}

function maltego () {

	dpkg -s maltego > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then
		if [ -f $githome/maltego/$vermaltego ]; then
			echo -ne "${cyan}[+]${end}${gray} Instalando Maltego ................. ${end}"
			sudo dpkg -i $githome/maltego/Maltego.v4.3.0.deb > /dev/null 2>&1
			checkfin
		else
			echo -e "${gray} No existe el fichero del instalador Maltego ${end}"
			echo -ne "${cyan}[+]${end}${gray} Instalando Maltego ................. ${end}"
			echo -e "[${red}X${end}]"
			exit 1
		fi
	else
		echo -ne "${cyan}[+]${end}${gray} Maltego ya instalado ................. ${end}"
		echo -e "[${yellow}!${end}]"
	fi

	echo -e "\n\t${blue} ** Maltego **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > maltego${end}\n"
}

function Osintgram () {
	echo -ne "${cyan}[+]${end}${gray} Instalando Osintgram ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/Osintgram ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de Osintgram no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/Osintgram
	pip install -r requirements.txt > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** Osintgram **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/Osintgram/ ${end}"
	echo -e "\t${cyan} > make setup ${end}"
	echo -e "\t${cyan} > python3 main.py <objetivo>${end}\n"
}

function osrframework () {
	echo -ne "${cyan}[+]${end}${gray} Instalando Osrframework ................. ${end}"

	#Se comprueba que existe el paquete Pip3
	if [ ! -f /usr/bin/pip3 ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	pip3 install osrframework > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** Osrframework **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > sudo osrf --help${end}\n"
}

function h8mail () {
	echo -ne "${cyan}[+]${end}${gray} Instalando h8mail ................. ${end}"

	#Se comprueba que existe el paquete Pip3
	if [ ! -f /usr/bin/pip3 ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	pip3 install h8mail > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** h8mail **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > h8mail --help${end}\n"
}

function spiderfoot () {
	echo -ne "${cyan}[+]${end}${gray} Instalando Spiderfoot ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/spiderfoot ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de Spiderfoot no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip3 ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/spiderfoot
	pip3 install -r requirements.txt > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** Spiderfoot **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/spiderfoot/ ${end}"
	echo -e "\t${cyan} > python3 ./sf.py -l 127.0.0.1:5001${end}\n"
}

function GHunt () {
	echo -ne "${cyan}[+]${end}${gray} Instalando GHunt ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/GHunt ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de GHunt no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip3 ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/GHunt
	pip3 install -r requirements.txt > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** GHunt **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/GHunt/ ${end}"
	echo -e "\t${cyan} > check_and_gen.py${end}"
	echo -e "\t${cyan} > python3 ghunt.py email larry@google.com${end}\n"
}

function SocialPwned () {
	echo -ne "${cyan}[+]${end}${gray} Instalando SocialPwned ................. ${end}"

	# Se comprueba que existe la carpeta del repositorio
	if [ ! -d $githome/SocialPwned ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} El repositorio de SocialPwned no se clonó correctamente \n${end}"
		exit 1
	fi
	#Se comprueba que existe el paquete Pip
	if [ ! -f /usr/bin/pip3 ]; then
		echo -e "${red}\n[!] ERROR:${end}${yellow} Pip no está instalado. Ejecute ./osintn31mcs8.sh -t para configurarlo. \n${end}"
		exit 1
	fi

	cd $githome/SocialPwned
	pip3 install --user --upgrade git+https://github.com/twintproject/twint.git@origin/master#egg=twint > /dev/null 2>&1
	pip3 install -r requirements.txt > /dev/null 2>&1
	checkfin

	echo -e "\n\t${blue} ** SocialPwned **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > cd $githome/SocialPwned/ ${end}"
	echo -e "\t${cyan} > python3 socialpwned.py --credentials credentials.json --help${end}\n"
}

function exiftool () {
	dpkg -s exiftool > /dev/null 2>&1
	if [ "$(echo $?)" != "0" ]; then	
		echo -ne "${cyan}[+]${end}${gray} Instalando exiftool ................. ${end}"
		sudo apt install exiftool -y > /dev/null 2>&1
		checkfin
	else
		echo -ne "${cyan}[+]${end}${gray} Exiftool ya instalado................. ${end}"
		echo -e "[${yellow}!${end}]"
	fi
	echo -e "\n\t${blue} ** exiftool **${end}${gray} Modo de uso:${end}\n"
	echo -e "\t${cyan} > exiftool -h ${end}\n"
}

function aplicaciones () {
	echo -e "${blue}[*]${end}${gray} Instalando aplicaciones: \n${end}"
	theHarvester
	dmitry
	recon-ng
	maltego
	Osintgram
	osrframework
	h8mail
	spiderfoot
	GHunt
	SocialPwned
	exiftool
}

function cabecera () {
	echo
	echo -e " ############################################################################"
    echo -e " #\t          ${blue}Master en Ciberseguridad VIII Edición ${end}                    #"
	echo -e " #     ${yellow}TFM 3.1 Distribución orientada a la obtención de datos en la red${end}     #"
	echo -e " #     ${yellow}Instalación de herramientas OSINT${end}                                    #"
	echo -e " #     Autor: Vicente Sanabria                                              #"
	echo -e " #     Tutores: Yaiza Rubio/Feliz Brezo                                     #"
	echo -e " ############################################################################"
	echo
	echo
}

function ayuda () {
	echo -e "${blue}[?] Uso: ${end}${yellow}./osintn31mcs8.sh [opcion]${end}"
	echo
	echo -e "Opciones:"
	echo -e "	${yellow}-h: ${end} Ofrece esta ayuda"
	echo -e "	${yellow}-a: ${end} Instala todos los elementos (requisitos, marcadores y aplicaciones)"
	echo -e "	${yellow}-b: ${end} Instala los marcadores en Firefox"
	echo -e "	${yellow}-p: ${end} Instala las aplicaciones de escritorio"
	echo -e "	${yellow}-t: ${end} Instala los requisitos necesarios de las aplicaciones"
	echo
}

# Variables
tf=`readlink -f $0`
path_actual=`dirname $tf`
declare githome
repositorios="laramies/theHarvester lanmaster53/recon-ng Datalux/Osintgram smicallef/spiderfoot mxrch/GHunt MrTuxx/SocialPwned"
vermaltego="Maltego.v4.3.0.deb"

trap ctrlc INT

function ctrlc () {
	echo -e "\n${gray}[*]${end}${red} ¡Ups, algo no te ha gustado!. Cancelando ...  ${end}"
	tput cnorm
	exit 2
}

# FUNCION MAIN
# El script no debe ser ejecutado por el usuario root ni como un usuario normal con permisos de root.
# El usuario debe pertenecer al grupo de sudoers y lanzar el script sin privilegios.
if [ "$(id -u)" == "0" ]; then
	cabecera
	echo
	echo -e "${yellow}[ADVERTENCIA] ${end}   El script no debe ser ejecutado con privilegios de root."
	echo -e "\t\t El usuario debe pertenecer al grupo sudoers y lanzar el script sin privilegios."
	echo -e "\t\t ${yellow}NOTA:${end} El script le solicitará su contraseña en caso de necesitarlo."
	echo
	echo -e "${blue}[?] Uso: ${end}${yellow}./osintn31mcs8.sh [opcion]${end}	     [${green}V${end}]"
	echo -e "${blue}[?] Uso: ${end}${yellow} sudo ./osintn31mcs8.sh [opcion]${end}    [${red}X${end}]"
	echo
	exit 1
fi

cabecera
tput civis
if [[ $1 == "-h" ]]; then
	ayuda
#Instalación de todo
elif [[ $1 == "-a" ]]; then
	requisitos
	sleep 3
	echo
	marcadores
	sleep 3
	echo
	entorno_git
	sleep 3
	echo
	clonar_proyectos
	sleep 3
	echo
	aplicaciones
#Instalación de los marcadores en Firefox
elif [[ $1 == "-b" ]]; then
	marcadores
#Instalación de las aplicaciones
elif [[ $1 == "-p" ]]; then
	entorno_git
	sleep 3
	echo
	clonar_proyectos
	sleep 3
	echo
	aplicaciones
#Instalación de los requisitos software
elif [[ $1 == "-t" ]]; then
	requisitos
else
	ayuda
fi
tput cnorm