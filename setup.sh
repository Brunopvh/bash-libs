#!/usr/bin/env bash
#
version='2021-02-21'
# Script para automatizar a instalação do gerenciador shm(Shell Package Manager).
#
# INSTALAÇÃO OFFLINE: chmod +x setup.sh; ./setup.sh
#
# INSTALAÇÃO ONLINE: sudo sh -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#                    sudo sh -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#

if [[ $(id -u) == 0 ]]; then
	DESTINATION_DIR='/usr/local/bin'
	PATH_BASH_LIBS='/usr/local/lib/bash'
else
	DESTINATION_DIR=~/.local/bin
	PATH_BASH_LIBS=~/.local/lib/bash
fi

[[ ! -d $DESTINATION_DIR ]] && mkdir -p $DESTINATION_DIR
[[ ! -d $PATH_BASH_LIBS ]] && mkdir -p $PATH_BASH_LIBS
DESTINATION_SCRIPT="$DESTINATION_DIR"/shm
URL_REPO_LIBS_MAIN='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'
TEMPORARY_DIR=$(mktemp -d)
DIR_UNPACK="$TEMPORARY_DIR/unpack"; mkdir -p $DIR_UNPACK
DIR_DOWNLOAD="$TEMPORARY_DIR/download"; mkdir -p $DIR_DOWNLOAD
PKG_LIBS="$DIR_DOWNLOAD/libs.tar.gz"
URL_REPO_LIBS_MAIN='https://github.com/Brunopvh/bash-libs/archive/main.tar.gz'

readonly _script=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$_script")

if [[ -x $(command -v aria2c) ]]; then
	clientDownloader='aria2c'
elif [[ -x $(command -v wget) ]]; then
	clientDownloader='wget'
elif [[ -x $(command -v curl) ]]; then
	clientDownloader='curl'
else
	printf "Instale o curl|wget|aria2 para prosseguir.\n"
	exit 1
fi

function online_setup()
{
	# Baixar os arquivos do repositório main.
	echo -ne "Baixando ... $URL_REPO_LIBS_MAIN "
	case "$clientDownloader" in
		aria2c) aria2c "$URL_REPO_LIBS_MAIN" -d $(dirname "$PKG_LIBS") -o $(basename "$PKG_LIBS") 1> /dev/null;;
		wget) wget -q -O "$PKG_LIBS" "$URL_REPO_LIBS_MAIN";;
		curl) curl -fsSL -o "$PKG_LIBS" "$URL_REPO_LIBS_MAIN";;
	esac

	[[ $? == 0 ]] || exit 1
	echo 'OK'
	cd $DIR_DOWNLOAD
	echo -ne "Descompactando ... "
	tar -zxvf "$PKG_LIBS" -C "$DIR_UNPACK" 1> /dev/null || exit 1
	echo 'OK'
	cd $DIR_UNPACK
	mv $(ls -d bash*) bash-libs
	cd bash-libs

	echo -e "Instalando módulos"
	cp -u ./libs/os.sh "$PATH_BASH_LIBS"/os.sh 1> /dev/null
	cp -u ./libs/utils.sh "$PATH_BASH_LIBS"/utils.sh 1> /dev/null
	cp -u ./libs/requests.sh "$PATH_BASH_LIBS"/requests.sh 1> /dev/null
	cp -u ./libs/print_text.sh "$PATH_BASH_LIBS"/print_text.sh 1> /dev/null
	cp -u ./libs/config_path.sh "$PATH_BASH_LIBS"/config_path.sh 1> /dev/null
	echo -ne "Instalando ... shm "
	cp -u shm.sh "$DESTINATION_SCRIPT" 1> /dev/null 
	chmod +x "$DESTINATION_SCRIPT"
}

function offline_setup()
{
	cd $dir_of_project
	[[ ! -d ./libs ]] && {
		echo "offline_setup ERRO: diretório libs não encontrado."
		return 1
	}

	[[ ! -f ./shm.sh ]] && {
		echo "offline_setup ERRO: arquivo shm.sh não encontrado."
		return 1
	}

	echo -ne "Copiando arquivos ... "
	cp ./libs/os.sh "$PATH_BASH_LIBS"/os.sh 1> /dev/null
	cp ./libs/requests.sh "$PATH_BASH_LIBS"/requests.sh 1> /dev/null
	cp ./libs/utils.sh "$PATH_BASH_LIBS"/utils.sh 1> /dev/null
	cp ./libs/print_text.sh "$PATH_BASH_LIBS"/print_text.sh 1> /dev/null
	cp ./libs/config_path.sh "$PATH_BASH_LIBS"/config_path.sh 1> /dev/null
	cp shm.sh "$DESTINATION_SCRIPT" 1> /dev/null
	chmod +x "$DESTINATION_SCRIPT"
	echo 'OK'
}

if [[ "$1" == 'install' ]]; then
	offline_setup
else
	online_setup
fi


if [[ -x "$DESTINATION_SCRIPT" ]]; then
	printf "Feito!\n"
	echo -e "Executando ... $DESTINATION_SCRIPT --configure"
	"$DESTINATION_SCRIPT" --configure
else
	printf "Falha"
	exit 1
fi

rm -rf "$TEMPORARY_DIR"

