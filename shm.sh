#!/usr/bin/env bash
#
#

readonly __version__='2021-03-14'
readonly __appname__='shm'
readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")

if [[ -x $(command -v aria2c) ]]; then
	clientDownloader='aria2c'
elif [[ -x $(command -v wget) ]]; then
	clientDownloader='wget'
elif [[ -x $(command -v curl) ]]; then
	clientDownloader='curl'
else
	echo "ERRO ... instale curl ou wget para prosseguir."
	exit 1
fi

function show_import_erro()
{
	echo "ERRO shm: $@"
	case "$clientDownloader" in
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

# Setar Diretório cache e arquivos de configuração.
if [[ $(id -u) == 0 ]]; then
	DIR_CACHE_SHM="/var/cache/$__appname__"
	DIR_CONFIG_SHM="/etc/$__appname__"
	PATH_BASH_LIBS='/usr/local/lib/bash'
	if [[ -f /etc/bashrc ]]; then
		readonly __bashrc_file__='/etc/bashrc'
	else
		readonly __bashrc_file__='/etc/bash.bashrc'
	fi
else
	DIR_CACHE_SHM=~/.cache/"$__appname__"
	DIR_CONFIG_SHM=~/.config/"$__appname__"
	PATH_BASH_LIBS=~/.local/lib/bash
	readonly __bashrc_file__=~/.bashrc
fi

# Setar o diretório das libs no sistema. apartir do arquivo de configuração.
source "$__bashrc_file__" 1> /dev/null 2>&1
source ~/.shmrc 1> /dev/null 2>&1

FILE_MODULES_LIST="$DIR_CONFIG_SHM/modules.list"
FILE_DB_APPS="$DIR_CONFIG_SHM/installed-apps.list"

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

readonly URL_RAW_REPO_MAIN='https://raw.github.com/Brunopvh/bash-libs/main'
readonly URL_RAW_REPO_DEVELOPMENT='https://raw.github.com/Brunopvh/bash-libs/development'
readonly URL_ARCHIVE='https://github.com/Brunopvh/bash-libs/archive'

readonly URL_TARFILE_LIBS="$URL_ARCHIVE/main.tar.gz"
readonly URL_MODULES_LIST="$URL_RAW_REPO_MAIN/libs/modules.list"
readonly URL_SHM="$URL_RAW_REPO_DEVELOPMENT/shm.sh"

function usage()
{
cat <<EOF
    Use: $__appname__ [opções] [argumentos]
         $__appname__ [agumento]

   Opções: 
     -h|--help                Mostra ajuda e sai.
     -c|--configure           Configura este programa para primeiro uso no sistema.
     -u|--self-update         Atualiza este programa para ultima versão disponível no github.
    
     -U|--upgrade             Instala a ultima versão de um módulo mesmo que este ja exista no sistema
                              essa opção deve ser usada com a opção --install.
                              EX: $__appname__ --upgrade --install requests pkgmanager
        
     -l|--list [Argumento]    Se não for passado nehum arguento, mostra os módulos disponíveis para instalação 
                              se receber o argumento [installed], mostra os módulos instalados para o seu usuário.
                                EX: $__appname__ --list
                                    $__appname__ --list installed

     -i|--install [módulo]    Instala um ou mais módulos.
                              EX: $__appname__ --install pkgmanager

     -r|--remove [módulo]     Remove um ou mais módulos.

     --info [módulo]          Mostra informações de um ou mais módulos.
                              EX: $__appname__ --info print_text platform

   Argumentos:
     up|update                Atualiza a lista de módulos disponíveis para instalação      


EOF
}

function create_dirs
{
	mkdir -p "$TEMPORARY_DIR"
	mkdir -p "$DIR_DOWNLOAD"
	mkdir -p "$DIR_UNPACK"
	mkdir -p "$DIR_CONFIG_SHM"
	mkdir -p "$DIR_CACHE_SHM"
	mkdir -p "$PATH_BASH_LIBS"
}

function clean_temp_files()
{
	rm -rf "$TEMPORARY_DIR" 2> /dev/null
	rm -rf "$TEMPORARY_FILE" 2> /dev/null
}


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

function install_file_modules_list()
{
	[[ -f $TEMPORARY_FILE ]] && rm -rf $TEMPORARY_FILE 2> /dev/null
	download "$URL_MODULES_LIST" "$TEMPORARY_FILE" 1> /dev/null 2>&1 &
	loop_pid "$!" "Baixando $URL_MODULES_LIST"
	export Upgrade='True'
	__copy_files "$TEMPORARY_FILE" "$FILE_MODULES_LIST" 
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
	print_line
	echo -e "${CGreen}I${CReset}nstalando os seguintes módulos/libs:\n"
	n=0
	for PKG in "${@}"; do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$PKG "
		n="$(($n + 1))"
	done
	echo

	echo -e "Baixando arquivos arguarde"
	download "$URL_TARFILE_LIBS" "$DIR_DOWNLOAD"/bash-libs.tar.gz 1> /dev/null 2>&1 || return 1
	[[ "$DownloadOnly" == 'True' ]] && print_info "Feito somente download!" && return 0
	
	unpack_archive "$DIR_DOWNLOAD"/bash-libs.tar.gz "$DIR_UNPACK" || return 1
	cd $DIR_UNPACK
	mv $(ls -d bash-*) bash-libs
	cd bash-libs/libs

	while [[ $1 ]]; do
		local module="$1"
		[[ "${module[@]:0:1}" == '-' ]] && {
			# Recebido uma opção ao inves de um argumento.
			print_erro "(install_modules) argumento inválido detectado ... $module"
			sleep 0.5
			return 1
			break
		}

		if [[ -f "${module}.sh" ]]; then
			__copy_files "${module}.sh" "$PATH_BASH_LIBS/${module}.sh" || { return 1; break; }
			grep -q ^"export readonly $module=$PATH_BASH_LIBS/${module}.sh" ~/.shmrc || {
					echo -e "export readonly $module=$PATH_BASH_LIBS/${module}.sh" >> ~/.shmrc
				}
		else
			print_erro "Módulo indisponível para instalação $string"
			sleep 0.5
		fi
		shift
	done
	echo 'Feito!'
}

function __configure__()
{
	install_file_modules_list || return 1
	config_bashrc
	config_zshrc	
	touch ~/.shmrc
	touch "$__bashrc_file__"

	# Criar backup do arquivo bashrc
	__backup_bashrc="${__bashrc_file__}.bak"
	if [[ -f "$__backup_bashrc" ]]; then
		echo -e "Backup encontrado ... $__backup_bashrc"
	else
		echo -e "Criando backup ... $__backup_bashrc"
		cp "$__bashrc_file__" "$__backup_bashrc"
	fi
	sleep 0.5

	# bashrc
	grep -q ^"export PATH_BASH_LIBS=$PATH_BASH_LIBS" "$__bashrc_file__" || {
		echo -e "export PATH_BASH_LIBS=$PATH_BASH_LIBS" >> "$__bashrc_file__"
	}

	# ~/.shmrc
	grep -q ^"source $__bashrc_file__" ~/.shmrc || {
		echo -e "source $__bashrc_file__" >> ~/.shmrc
	}

	#sed -i '/PATH_BASH_LIBS/d' $FILE_CONFIG
	sed -i "/export readonly PATH_BASH_LIBS/d" "$__bashrc_file__"
}

function show_info_modules()
{
	[[ -z $1 ]] && print_erro 'Falta um ou mais argumentos.' && exit 1
	print_line '*'
	for MOD in "${@}"; do
		if grep -q ^"$MOD" "$FILE_MODULES_LIST"; then
			grep ^"$MOD" "$FILE_MODULES_LIST"
		else
			print_erro "módulo não encontrado ... $MOD"
		fi
	done
}

function get_installed_modules()
{
	# find "$PATH_BASH_LIBS" -name '*.sh'
	echo '' > "$FILE_DB_APPS"
	find "$PATH_BASH_LIBS" -name '*.sh' | sed 's|.*/||g;s|.sh||g' >> "$FILE_DB_APPS"
}

function list_modules()
{
	if [[ -z $1 ]]; then
		cut -d '=' -f 1 "$FILE_MODULES_LIST"
	elif [[ "$1" == 'installed' ]]; then
		find "$PATH_BASH_LIBS" -name '*.sh'	
	fi
}

function self_update()
{
	cd "$dir_of_project"
	env AssumeYes='True' ./setup.sh
}

function main_shm()
{
	create_dirs

	for ARG in "${@}"; do
		case "$ARG" in
			-y|--yes) AssumeYes='True';;
			-d|--downloadonly) DownloadOnly='True';;
			-U|--upgrade) Upgrade='True';;
			-h|--help) usage; return 0; break;;
			-v|--version) echo -e "$__version__"; return 0; break;;
		esac
	done

	[[ -f $FILE_MODULES_LIST ]] || install_file_modules_list

	while [[ $1 ]]; do
		case "$1" in
			-U|--upgrade) ;;
			-y|--yes) ;;
			-d|--downloadonly) ;;
			-v|--version) ;;
			-h|--help) ;;
			-c|--configure) __configure__; return "$?"; break;;
			-u|--self-update) self_update; break;;
			-i|--install) shift; install_modules "$@"; return "$?"; break;;
			-r|--remove) shift; remove_modules "$@";;
			-l|--list) shift; list_modules "$@";;

			--info) shift; show_info_modules "$@";;
			
			
			up|update) install_file_modules_list;;
			*) print_erro "argumento invalido detectado."; return 1; break;;
		esac
		shift
	done

	clean_temp_files
}


if [[ ! -z $1 ]]; then
	ArgumentsList=()
	ListIntallerModules=()
	ListRemoveModules=()
	main_shm "$@" 
fi
	