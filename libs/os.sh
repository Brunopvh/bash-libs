#!/usr/bin/env bash
#
version_os='2021-02-21'
# - REQUERIMENT = print_text
# - REQUERIMENT = utils
#

function show_import_erro()
{
	echo "ERRO: $@"
	if [[ -x $(command -v curl) ]]; then
		echo -e "Execute ... bash -c \"\$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
	elif [[ -x $(command -v wget) ]]; then
		echo -e "Execute ... bash -c \"\$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
	fi
	sleep 3
}

# print_text
[[ $imported_print_text != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/print_text.sh 2> /dev/null; then
		show_import_erro "módulo print_text.sh não encontrado em ... $PATH_BASH_LIBS"
		exit 1
	fi
}

# utils
[[ $imported_utils != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/utils.sh 2> /dev/null; then
		show_import_erro "módulo utils.sh não encontrado em ... $PATH_BASH_LIBS"
		exit 1
	fi
}

#=============================================================#

export imported_os='True'

if [[ $(id -u) == 0 ]]; then
	export readonly DIR_BIN='/usr/local/bin'
	export readonly DIR_LIB='/usr/local/lib'
	export readonly DIR_OPTIONAL='/opt'
	export readonly DIR_SHARE='/usr/share'
	export readonly DIR_THEMES='/usr/share/themes'
	export readonly DIR_APPLICATIONS='/usr/share/applications'
	export readonly DIR_ICONS='/usr/share/icons/hicolor/256x256/apps'
	export readonly DIR_HICOLOR='/usr/share/icons/hicolor'
else
	export readonly DIR_BIN=~/.local/bin
	export readonly DIR_LIB=~/.local/lib
	export readonly DIR_SHARE=~/.local/share
	export readonly DIR_THEMES=~/.themes
	export readonly DIR_OPTIONAL=~/.local/share
	export readonly DIR_APPLICATIONS=~/.local/share/applications
	export readonly DIR_ICONS=~/.local/share/icons
	export readonly DIR_HICOLOR=~/.icons
fi

[[ ! -d $DIR_BIN ]] && mkdir "$DIR_BIN"
[[ ! -d $DIR_LIB ]] && mkdir "$DIR_LIB"
[[ ! -d $DIR_OPTIONAL ]] && mkdir "$DIR_OPTIONAL"
[[ ! -d $DIR_SHARE ]] && mkdir "$DIR_SHARE"
[[ ! -d $DIR_THEMES ]] && mkdir "$DIR_THEMES"
[[ ! -d $DIR_APPLICATIONS ]] && mkdir "$DIR_APPLICATIONS"
[[ ! -d $DIR_ICONS ]] && mkdir "$DIR_ICONS"
[[ ! -d $DIR_HICOLOR ]] && mkdir "$DIR_HICOLOR"

kernel_type=$(uname -s)

is_admin(){
	printf "Autênticação necessária para prosseguir "
	if [[ $(sudo id -u) == 0 ]]; then
		printf "OK\n"
		return 0
	else
		sred "ERRO"
		return 1
	fi
}

is_executable()
{
	# Função para verificar se um executável existe no PATH do sistema.
	if [[ -x $(which "$1" 2> /dev/null) ]]; then
		return 0
	else
		return 1
	fi
}

function __rmdir__()
{
	# Função para remover diretórios e arquivos, inclusive os arquivos é diretórios
	# que o usuário não tem permissão de escrita, para isso será usado o "sudo".
	#
	# Use:
	#     __rmdir__ <diretório> ou
	#     __rmdir__ <arquivo>
	# Se o arquivo/diretório não for removido por falta de privilegio 'root'
	# o comando de remoção será com 'sudo'.
	[[ -z $1 ]] && return 1

	local msg="Deseja ${CRed}deletar${CReset} os seguintes arquivos/diretórios? : $@\n"
	question "$msg" || return 1

	while [[ $1 ]]; do		
		cd $(dirname "$1")
		if [[ -f "$1" ]] || [[ -d "$1" ]] || [[ -L "$1" ]]; then
			printf "Removendo ... $1\n"
			rm -rf "$1" 2> /dev/null || sudo rm -rf "$1"
			sleep 0.08
		else
			red "Não encontrado ... $1"
		fi
		shift
	done
}

function __copy__()
{
	echo -ne "Copiando ... $1 "
	if cp -R "$1" "$2"; then
		echo 'OK'
		return 0
	else
		red "Falha"
		return 1
	fi
}

get_type_file()
{
	# Usar o comando "file" para obter o cabeçalho de um arquivo qualquer.
	[[ -z $1 ]] && return 1
	[[ -x $(command -v file) ]] || {
		echo 'None'
		return 1
	}

	file "$1" | cut -d ' ' -f 2
}

__sudo__()
{
	# Função para executar comandos com o "sudo" e retornar '0' ou '1'.
	echo -e "${CYellow}E${CReset}xecutando ... sudo $@"
	if sudo "$@"; then
		return 0
	else
		red "Falha ... sudo $@"
		return 1
	fi
}

function unpack_archive()
{
	# $1 = arquivo a ser descomprimido - (obrigatório)
	# $2 = diretório de saida - (opcional)

	[[ ! -f "$1" ]] && {
		red "(unpack_archive): nenhum arquivo informado no parâmetro 1."
		return 1
	}

	if [[ "$2" ]]; then 
		DirUnpack="$2"
	elif [[ -z "$DirUnpack" ]]; then
		DirUnpack=$(pwd)
	fi

	[[ ! -w "$DirUnpack" ]] && { 
		red "Você não tem permissão de escrita [-w] em ... $DirUnpack"
		return 1	
	}

	#printf "Entrando no diretório ... $DirUnpack\n"; cd "$DirUnpack"
	
	path_file="$1"
	if [[ -x $(command -v file) ]]; then
		# Detectar o tipo de arquivo com o comando file.
		extension_file=$(get_type_file "$path_file")
	else
		# Detectar o tipo de arquivo apartir da extensão.
		if [[ "${path_file: -6}" == 'tar.gz' ]]; then    # tar.gz - 6 ultimos caracteres.
			extension_file='gzip'
		elif [[ "${path_file: -7}" == 'tar.bz2' ]]; then # tar.bz2 - 7 ultimos carcteres.
			extension_file='bzip2'
		elif [[ "${path_file: -6}" == 'tar.xz' ]]; then  # tar.xz
			extension_file='XZ'
		elif [[ "${path_file: -4}" == '.zip' ]]; then    # .zip
			extension_file='Zip'
		elif [[ "${path_file: -4}" == '.deb' ]]; then    # .deb
			extension_file='Debian'
		else
			printf "${CRed}(unpack_archive): Arquivo não suportado ... $path_file${CReset}\n"
			return 1
		fi
	fi

	# Calcular o tamanho do arquivo
	local len_file=$(du -hs $path_file | awk '{print $1}')
	
	# Descomprimir de acordo com cada extensão de arquivo.	
	if [[ "$extension_file" == 'gzip' ]]; then
		tar -zxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'bzip2' ]]; then
		tar -jxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'XZ' ]]; then
		tar -Jxf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'Zip' ]]; then
		unzip "$path_file" -d "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'Debian' ]]; then
		
		if [[ -f /etc/debian_version ]]; then    # Descompressão em sistemas DEBIAN
			ar -x "$path_file" 1> /dev/null 2>&1  &
		else                                     # Descompressão em outros sistemas.
			ar -x "$path_file" --output="$DirUnpack" 1> /dev/null 2>&1 &
		fi
	fi

	# echo -e "$(date +%H:%M:%S)"
	loop_pid "$!" "Descompactando ... [$extension_file] ... $(basename $path_file)"
	return 0
}


function add_desktop_file()
{
	OutFile="$1"
	Array=$2
	
	echo '[Desktop Entry]' > $OutFile
	shift
	while [[ $1 ]]; do
		echo "Criando ... $1"
		echo "$1" >> $OutFile
		shift
	done
}