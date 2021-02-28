#!/usr/bin/env bash
#
#

readonly __version__='2021-02-28'
readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")

if [[ -x $(command -v aria2c) ]]; then
	clientDownload='aria2c'
elif [[ -x $(command -v wget) ]]; then
	clientDownload='wget'
elif [[ -x $(command -v curl) ]]; then
	clientDownload='curl'
else
	echo "ERRO ... instale curl ou wget para prosseguir."
	exit 1
fi

function show_import_erro()
{
	echo "ERRO shm: $@"
	case "$clientDownload" in
		curl) 
			echo -e "Execute ... bash -c \"\$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
			;;
		wget)
			echo -e "Execute ... bash -c \"\$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
			;;
		aria2c)
			echo -e "Execute ... aria2c https://raw.github.com/Brunopvh/bash-libs/main/setup.sh -o setup.sh; bash setup.sh; rm setup.sh"
			;;
	esac
	sleep 1
}

# Setar o diretório das libs no sistema. apartir do arquivo de configuração.
source ~/.shmrc 1> /dev/null 2>&1

# Setar diretório para importar os módulos.
if [[ -d "$dir_of_project/libs" ]]; then
	__dir_bash_libs__="$dir_of_project/libs" # Importar do diretório deste projeto.
elif [[ -d "$PATH_BASH_LIBS" ]]; then
	__dir_bash_libs__="$PATH_BASH_LIBS" # Importar do sistema
fi

[[ ! -d $__dir_bash_libs__ ]] && {
	show_import_erro "Diretório para importação de módulos não encontrado."
	exit 1
}

# Módulos em bash necessários para o funcionamento deste programa.
readonly RequerimentsList=(
	os.sh
	utils.sh
	print_text.sh
	requests.sh
	config_path.sh
	)

function check_local_modules()
{
	for MOD in "${RequerimentsList[@]}"; do
		if [[ ! -f "$__dir_bash_libs__/$MOD" ]]; then
			show_import_erro "Módulo não encontrado $__dir_bash_libs__/$MOD"
			return 1
			break
		fi
	done
	return 0
}

check_local_modules || exit 1
source "$__dir_bash_libs__"/print_text.sh
source "$__dir_bash_libs__"/utils.sh
source "$__dir_bash_libs__"/os.sh
source "$__dir_bash_libs__"/requests.sh
source "$__dir_bash_libs__"/config_path.sh


readonly TEMPORARY_DIR=$(mktemp --directory -u)
readonly TEMPORARY_FILE=$(mktemp -u)
readonly DIR_UNPACK="$TEMPORARY_DIR/unpack"
readonly DIR_DOWNLOAD="$TEMPORARY_DIR/download"

readonly URL_REPO_LIBS_MASTER='https://github.com/Brunopvh/bash-libs/archive/main.tar.gz'
readonly URL_MODULES_LIST='https://raw.github.com/Brunopvh/bash-libs/main/libs/modules.list'
readonly URL_SHM='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'


function create_dirs
{
	mkdir -p "$TEMPORARY_DIR"
	mkdir -p "$DIR_DOWNLOAD"
	mkdir -p "$DIR_UNPACK"
}

function clean_temp_files()
{
	rm -rf "$TEMPORARY_DIR" 2> /dev/null
	rm -rf "$TEMPORARY_FILE" 2> /dev/null
}

function __copy_files()
{
	if [[ "$Upgrade" == 'True' ]]; then
		echo -ne "Atualizando ... $2 "
		cp -r -u "$1" "$2" 1> /dev/null 2>&1
	else
		echo -ne "Instalando ... $2 "
		if [[ -f "$2" ]]; then
			echo "... módulo já instalado [PULANDO]"
			return 0
		else
			cp "$1" "$2" 1> /dev/null 2>&1
		fi 
	fi

	[[ $? == 0 ]] && echo 'OK' && return 0
	echo 'ERRO' && return 1
}

function install_modules()
{
	echo -e "Baixando arquivos arguarde"
	download "$URL_REPO_LIBS_MASTER" "$DIR_DOWNLOAD"/bash-libs.tar.gz 1> /dev/null || return 1
	unpack_archive "$DIR_DOWNLOAD"/bash-libs.tar.gz "$DIR_UNPACK" || return 1
	cd $DIR_UNPACK
	mv $(ls -d bash-*) bash-libs
	cd bash-libs/libs

	while [[ $1 ]]; do
		local string="$1"
		[[ "${string[@]:0:1}" == '-' ]] && {
			# Recebido uma opção ao inves de um argumento.
			print_erro "(install_modules) argumento inválido detectado ... $string"
			sleep 0.5
			return 1
			break
		}

		case "$string" in
			os) __copy_files "os.sh" "$PATH_BASH_LIBS"/os.sh;;
			requests) __copy_files "requests.sh" "$PATH_BASH_LIBS"/requests.sh;;
			*) print_erro "Módulo indisponível para instalação $string"; sleep 0.5;;
		esac
		shift
	done
}

function argument_parse()
{
	local num=0
	while [[ $1 ]]; do
		case "$1" in
			-y|--yes) AssumeYes='True';;
			-d|--downloadonly) DownloadOnly='True';;
			-U|--upgrade) Upgrade='True';;
			*) ArgumentsList["$num"]="$1"; num=$(($num + 1));;
		esac
		shift
	done
}

function main_shm()
{
	create_dirs
	argument_parse "$@"

	local num=0
	for ARG in "${ArgumentsList[@]}"; do

		case "$ARG" in
			-i|--install)
					num=$(($num + 1))
					install_modules "${ArgumentsList[@]:$num}"
					;;	
		esac
		num=$(($num + 1))
	done

	clean_temp_files
}


if [[ ! -z $1 ]]; then
	ArgumentsList=()
	ListIntallerModules=()
	ListRemoveModules=()
	main_shm "$@" 
fi
	