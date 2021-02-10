#!/usr/bin/env bash
#
# Este script instala módulos/libs para o bash, para facilitar a importação de 
# códigos em bash. Semelhante ao pip do python.

readonly __version__='2021-02-09'
readonly __appname__='shell-pkg-manager'
readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")
#readonly temp_dir="$(mktemp --directory)-$__appname__"
readonly temp_dir="/tmp/${USER}-${__appname__}"
readonly URL_REPO_LIBS_MASTER='https://github.com/Brunopvh/bash-libs/archive/main.tar.gz'
readonly FILE_LIBS_TAR="$temp_dir/libs.tar.gz"
readonly PATH_BASH_LIBS=~/.local/lib/bash-libs
readonly DIR_BIN=~/.local/bin

COLUMNS=$(tput cols)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[m'

function _red() { echo -e "${RED}$@${RESET}"; }
function _green() { echo -e "${GREEN}$@${RESET}"; }
function _yellow() { echo -e "${YELLOW}$@${RESET}"; }
function _blue() { echo -e "${BLUE}$@${RESET}"; }

[[ $(id -u) == 0 ]] && {
	_red "Você não pode ser o 'root'. Saindo..."
	exit 1 
}

mkdir -p "$temp_dir"
mkdir -p "$PATH_BASH_LIBS"
mkdir -p "$DIR_BIN"

function is_executable()
{
	command -v "$@" >/dev/null 2>&1
}

function print_line()
{
	if [[ -z $1 ]]; then
		char='-'
	else
		char="$1"
	fi
	printf "%-${COLUMNS}s" | tr ' ' "$char"
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
	while [[ $1 ]]; do		
		cd $(dirname "$1")
		if [[ -f "$1" ]] || [[ -d "$1" ]] || [[ -L "$1" ]]; then
			printf "Removendo ... $1\n"
			rm -rf "$1" 2> /dev/null || sudo rm -rf "$1"
			sleep 0.08
		else
			_red "Não encontrado ... $1"
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
		_red "Falha"
		return 1
	fi
}

function __download__()
{
	[[ -f "$2" ]] && {
		echo -e "Arquivo encontrado ...$2"
		return 0
	}

	local url="$1"
	local path_file="$2"
	local count=3
	
	cd "$temp_dir"
	[[ ! -z $path_file ]] && echo -e "Salvando ... $path_file"
	echo -e "Conectando ... $1"
	while true; do
		if [[ ! -z $path_file ]]; then
			if is_executable aria2c; then
				aria2c -c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" && break
			elif is_executable curl; then
				curl -C - -S -L -o "$path_file" "$url" && break
			elif is_executable wget; then
				wget -c "$url" -O "$path_file" && break
			else
				return 1
				break
			fi
		else
			if is_executable aria2c; then
				aria2c -c "$url" -d "$temp_dir" && break
			elif is_executable curl; then
				curl -C - -S -L -O "$url" && break
			elif is_executable wget; then
				wget -c "$url" && break
			else
				return 1
				break
			fi
		fi

		_red "Falha no download"
		sleep 2
		local count="$(($count-1))"
		if [[ $count > 0 ]]; then
			_yellow "Tentando novamente. Restando [$count] tentativa(s) restante(s)."
			continue
		else
			[[ -f "$path_file" ]] && __rmdir__ "$path_file"
			_red "$(print_line)"
			return 1
			break
		fi
	done
	if [[ "$?" == '0' ]]; then
		return 0
	else
		_red "$(print_line)"
	fi
}

function _install_modules()
{
	print_line
	echo -e "${GREEN}I${RESET}nstalando os seguintes pacotes:\n"
	n=0
	for PKG in "${@}"; do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$PKG "

		n="$(($n + 1))"
	done
	echo
	print_line

	__download__ "$URL_REPO_LIBS_MASTER" "$FILE_LIBS_TAR" || return 1
	cd "$temp_dir"
	echo -ne "Descompactando ... $FILE_LIBS_TAR "
	tar -zxvf "$FILE_LIBS_TAR" -C "$temp_dir" 1> /dev/null || return 1
	echo 'OK'
	cd $(ls -d bash-libs*)
	cd libs
	
	while [[ $1 ]]; do
		case "$1" in
			print_text) 
					__copy__ print_text.sh "$PATH_BASH_LIBS"/print_text.sh
					;;
			config_path) 
					__copy__ config_path.sh "$PATH_BASH_LIBS"/config_path.sh
					;;
			os) __copy__ os.sh "$PATH_BASH_LIBS"/os.sh;;
			*) _red "pacote indisponivel ... $PKG";;
		esac
		shift
	done
	echo -e "Feito!"
}

function _remove_modules()
{
	echo
}

# Lista de todos o módulos disponíveis para instalação.
readonly OnlineModules=(
	'print_text'
	'config_path'
	'os'
	)

function self_update()
{
	local url_shm_main='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'
	local temp_update="$(mktemp)-shm-update"
	
	__download__ "$url_shm_main" "$temp_update" || return 1
	cp "$temp_update" "$HOME"/.local/bin/shm
	chmod +x "$HOME"/.local/bin/shm
	shm --version
}

function list_online_modules()
{
	n=0
	for P in "${OnlineModules[@]}"; do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$P "
		n="$(($n + 1))"
	done
	echo
}

_configure()
{
	[[ -f ~/.bashrc ]] && source ~/.bashrc
	[[ -z $HOME ]] && HOME=~/

	_install_modules config_path 
	source "$PATH_BASH_LIBS"/config_path.sh 2> /dev/null
	backup
	config_bashrc

	touch ~/.shmrc
	grep -q -m 1 'export PATH_BASH_LIBS=' ~/.shmrc && return 0
	echo -e "export PATH_BASH_LIBS=$HOME/.local/lib/bash-libs" >> ~/.shmrc
}

# OptionList
OptionList=()
PkgsList=()
function argument_parse()
{
	[[ -z $1 ]] && return 1
	local num=0
	for OPT in "$@"; do
		OptionList["$num"]="$OPT"
		num="$(($num + 1))"
	done

	# Parse
	num=0
	num_pkg=0
	# Percorrer todoa arguemtos.
	for OPT in "${OptionList[@]}"; do
		if [[ "$OPT" == '--install' ]]; then
			# Verificar quais argumentos vem depois da opção --install.
			# o loop será quebrado quando encontrar outra opção ou seja -- ou -.
			for pkg in "${OptionList[@]:$num}"; do
				if [[ "$pkg" != '--install' ]]; then
					# Verificar se o primeiro caracter e igual a -. Se for o loop deve ser
					# encerrado pois é uma opção e não um pacote.
					echo -e "${pkg[@]:0:1}" | grep -q '-' && break
			
					# Adicionar os elementos no array que guarda os pacotes de instalação.
					PkgsList["$num_pkg"]="$pkg"
					num_pkg="$(($num_pkg + 1))"
					num="$(($num + 1))"
				fi
			done
		fi

		num="$(($num + 1))"
	done
}

function main()
{
	argument_parse "$@"

	while [[ $1 ]]; do
		case "$1" in
			--install) _install_modules "${PkgsList[@]}";;
			--remove) _remove_modules;;
			--configure) _configure;;
			--self-install) 
					cp "$__script__" "$DIR_BIN"/shm
					chmod +x "$DIR_BIN"/shm
				;;
			--self-update) self_update;;
			--list) list_online_modules;;
			--version) echo -e "$__version__";;
			*) ;;
		esac
		shift
	done
}

if [[ ! -z $1 ]]; then
	main "$@"
fi
