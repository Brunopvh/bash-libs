#!/usr/bin/env bash
#
# Script para automatizar a instalação do gerenciador shm (Shell Package Manager).
#
# INSTALAÇÃO OFFLINE: chmod +x setup.sh 
#                     ./setup.sh
#
# INSTALAÇÃO ONLINE: 
#                    sudo bash -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#                    sudo bash -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#

version='2021-02-28'

# Definir o destino dos módulos e do script shm.
if [[ $(id -u) == 0 ]]; then
	DIR_OPTIONAL='/opt/shell-package-manager'
	DIR_BIN='/usr/local/bin'
	PATH_BASH_LIBS='/usr/local/lib/bash'
else
	DIR_OPTIONAL=~/.local/share/'shell-package-manager'
	DIR_BIN=~/.local/bin
	PATH_BASH_LIBS=~/.local/lib/bash
fi

readonly TEMPORARY_DIR=$(mktemp --directory)
readonly TEMPORARY_FILE=$(mktemp -u)
readonly DIR_UNPACK="$TEMPORARY_DIR/unpack"
readonly DIR_DOWNLOAD="$TEMPORARY_DIR/download"

readonly URL_RAW_REPO_MAIN='https://raw.github.com/Brunopvh/bash-libs/main'
readonly URL_RAW_REPO_DEVELOPMENT='https://raw.github.com/Brunopvh/bash-libs/development'
readonly URL_ARCHIVE='https://github.com/Brunopvh/bash-libs/archive'
readonly URL_TARFILE_LIBS="$URL_ARCHIVE/main.tar.gz"

readonly FILE_TAR_LIBS="$DIR_DOWNLOAD/libs.tar.gz"

if [[ -d "$DIR_OPTIONAL" && "$AssumeYes" != 'True' ]]; then
	echo
	echo -e "Existe uma versão do gerenciador de pacotes shm instalada em seu sistema"
	read -p "Deseja substituir pela versão do github [s/N]?: " -n 1 -t 60 opt
	echo
	[[ "${opt,,}" == 's' ]] || exit 1
fi

mkdir -p $DIR_UNPACK
mkdir -p $DIR_DOWNLOAD
mkdir -p $DIR_OPTIONAL
mkdir -p $DIR_OPTIONAL/libs
mkdir -p $PATH_BASH_LIBS
mkdir -p $DIR_BIN

readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")

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

function exists_file()
{
	# Verificar a existencia de arquivos
	# $1 = Arquivo a verificar.
	# Também suporta uma mais de um arquivo a ser testado.
	# exists_file arquivo1 arquivo2 arquivo3 ...
	# se um arquivo informado como parâmetro não existir, esta função irá retornar 1.

	[[ -z $1 ]] && return 1
	export STATUS_OUTPUT=0

	while [[ $1 ]]; do
		if [[ ! -f "$1" ]]; then
			export STATUS_OUTPUT=1
			echo -e "ERRO ... o arquivo não existe $1"
			#sleep 0.05
		fi
		shift
	done

	[[ "$STATUS_OUTPUT" == 0 ]] && return 0
	return 1
}


function __ping__()
{
	[[ ! -x $(command -v ping) ]] && {
		echo -e "ERRO ... " "(__ping__) ... comando ping não instalado."
		return 1
	}

	if ping -c 1 8.8.8.8 1> /dev/null 2>&1; then
		return 0
	else
		echo -e "ERRO ... " "você está off-line"
		return 1
	fi
}

function download()
{
	# Baixa arquivos da internet.
	# Requer um gerenciador de downloads wget, curl, aria2
	# 
	# https://curl.se/
	# https://www.gnu.org/software/wget/
	# https://aria2.github.io/manual/pt/html/README.html
	# 
	# $1 = URL
	# $2 = Output File - (Opcional)
	#

	[[ -f "$2" ]] && {
		echo -e "Arquivo encontrado ...$2"
		return 0
	}

	local url="$1"
	local path_file="$2"

	if [[ -z "$clientDownloader" ]]; then
		echo -e "ERRO ... " "(download) Instale curl|wget|aria2c para prosseguir."
		sleep 0.1
		return 1
	fi

	__ping__ || return 1
	echo -e "Conectando ... $url"
	if [[ ! -z $path_file ]]; then
		case "$clientDownloader" in 
			aria2c) 
					aria2c -c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" 
					;;
			curl)
				curl -C - -S -L -o "$path_file" "$url"
					;;
			wget)
				wget -c "$url" -O "$path_file"
					;;
		esac
	else
		case "$clientDownloader" in 
			aria2c) 
					aria2c -c "$url"
					;;
			curl)
					curl -C - -S -L -O "$url"
					;;
			wget)
				wget -c "$url"
					;;
		esac
	fi

	[[ $? == 0 ]] && echo 'OK' && return 0
	echo -e "ERRO ... " '(download)'
	return 1
}

function install_shell_package_manager()
{
	echo -ne "Instalando libs ... "
	cp -r -u ./libs/os.sh "$DIR_OPTIONAL"/libs/os.sh 1> /dev/null
	cp -r -u ./libs/utils.sh "$DIR_OPTIONAL"/libs/utils.sh 1> /dev/null
	cp -r -u ./libs/requests.sh "$DIR_OPTIONAL"/libs/requests.sh 1> /dev/null
	cp -r -u ./libs/print_text.sh "$DIR_OPTIONAL"/libs/print_text.sh 1> /dev/null
	cp -r -u ./libs/config_path.sh "$DIR_OPTIONAL"/libs/config_path.sh 1> /dev/null
	cp -r -u ./setup.sh "$DIR_OPTIONAL"/setup.sh 1> /dev/null
	[[ $? == 0 ]] || return 1
	echo 'OK'

	echo -ne "Instalando shm ... em $DIR_OPTIONAL "
	cp -r -u shm.sh "$DIR_OPTIONAL"/shm.sh
	chmod a+x "$DIR_OPTIONAL"/shm.sh
	ln -sf "$DIR_OPTIONAL"/shm.sh "$DIR_BIN"/shm
	[[ $? == 0 ]] || return 1
	echo 'OK'
}

function online_setup()
{
	# Baixar os arquivos do repositório main.
	echo -ne "Baixando arquivos aguarde "
	download "$URL_TARFILE_LIBS" "$FILE_TAR_LIBS" 1> /dev/null 2>&1 || return 1
	echo 'OK'

	cd $DIR_DOWNLOAD
	echo -ne "Descompactando ... "
	tar -zxvf "$FILE_TAR_LIBS" -C "$DIR_UNPACK" 1> /dev/null || return 1
	echo 'OK'
	cd $DIR_UNPACK
	mv $(ls -d bash*) bash-libs
	cd bash-libs
	install_shell_package_manager
}

function offline_setup()
{
	cd $dir_of_project
	[[ ! -d ./libs ]] && {
		echo "ERRO offline_setup: diretório libs não encontrado."
		return 1
	}

	[[ ! -f ./shm.sh ]] && {
		echo "ERRO offline_setup: arquivo shm.sh não encontrado."
		return 1
	}

	# Verificar a existência dos módulos/dependências locais.
	exists_file ./libs/os.sh ./libs/requests.sh ./libs/utils.sh ./libs/print_text.sh ./libs/config_path.sh || return 1
	install_shell_package_manager
}

if [[ "$1" == 'install' ]]; then
	offline_setup || exit 1
else
	online_setup || exit 1
fi


if [[ -x "$DIR_BIN/shm" ]]; then
	echo -e "Configurando"
	"$DIR_BIN/shm" --configure
	printf "Feito!\n"
else
	printf "Falha\n"
	exit 1
fi

rm -rf "$TEMPORARY_DIR" 2> /dev/null
rm -rf "$TEMPORARY_FILE" 2> /dev/null
