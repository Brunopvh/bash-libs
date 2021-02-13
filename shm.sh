#!/usr/bin/env bash
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Shell Package Manager
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#
# Este script instala módulos/libs para o bash, para facilitar a importação de 
# códigos em bash. Semelhante ao pip do python.
#
#--------------------------------------------------#
# URL/INSTALAÇÃO
#--------------------------------------------------#
# https://github.com/Brunopvh/bash-libs
# sudo sh -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#
#--------------------------------------------------#
# USO
#--------------------------------------------------#
# Depois de executar o script de instalação configure o 
# programa para primeiro uso.
#   Verifique se a instalação foi efetuada correntamente
# >> $ ls ~/.local/bin/shm OU
# >> $ ls /usr/local/bin/shm
#
# E recomendado passar o caminho absoluto do programa na primeira execução
# para evitar problemas com o PATH do usuário, se a instalação foi feita como
# root ou sudo NÃO é necessário passar o caminho absoluto para chamada deste
# script pois '/usr/local/bin' já está incluso no PATH na maioria das Distros.
# PARA INSTALAÇÃO NA HOME: ~/.local/bin/shm --configure
# PARA INSTALAÇÃO ROOT: shm --configure
#
# PRONTO agora você pode usar o script para instalar os módulos disponíveis no
# github. NÃO é recomendado usar root ou sudo diretamente (embora funcione).
#
# $ shm --list => Exibe os módulos disponíveis
# $ shm --help => Mostra ajuda
# $ shm update => Atualiza a lista de modulos.
# $ shm --install <módulo> Exemplo shm --install requests os print_text
#                          Instala os módulos os, print_text e requests.
#
# $ shm --self-update => Atualiza este script para ultima versão disponível no github.
# 
# 
#
#
#

readonly __version__='2021-02-13'
readonly __author__='Bruno Chaves'
readonly __appname__='shell-pkg-manager'
readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")
readonly temp_dir=$(mktemp --directory); mkdir -p "$temp_dir"
readonly URL_REPO_LIBS_MASTER='https://github.com/Brunopvh/bash-libs/archive/main.tar.gz'
readonly URL_MODULES_LIST='https://raw.github.com/Brunopvh/bash-libs/main/libs/modules.list'
readonly FILE_LIBS_TAR="$temp_dir/bash-libs.tar.gz"
readonly url_shell_pkg_manager='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'

if [[ $(id -u) == 0 ]]; then
	readonly PATH_BASH_LIBS='/usr/local/lib/bash'
	readonly DIR_BIN='/usr/local/bin'
	readonly DIR_CONFIG="/etc/${__appname__}"
else
	readonly PATH_BASH_LIBS=~/.local/lib/bash
	readonly DIR_BIN=~/.local/bin
	readonly DIR_CONFIG=~/".config/${__appname__}"
fi

readonly FILE_CONFIG=~/.shmrc
readonly MODULES_LIST="$DIR_CONFIG/modules.list"

[[ -f ~/.bashrc ]] && source ~/.bashrc
[[ -z $HOME ]] && HOME=~/
[[ ! -d $DIR_CONFIG ]] && mkdir $DIR_CONFIG

# Argumentos/Opções passados na linha de comando.
OptionList=() 

# Lista de pacotes a serem instalados.
PkgsList=()

# Verificar gerenciador de downloads.
if [[ -x $(command -v wget) ]]; then
	Downloader='wget'
elif [[ -x $(command -v aria2c) ]]; then
	Downloader='aria2c'
elif [[ -x $(command -v curl) ]]; then
	Downloader='curl'
fi

COLUMNS=$(tput cols)
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
RESET='\e[m'

function _red() { echo -e "${RED}$@${RESET}"; }
function _green() { echo -e "${GREEN}$@${RESET}"; }
function _yellow() { echo -e "${YELLOW}$@${RESET}"; }
function _blue() { echo -e "${BLUE}$@${RESET}"; }


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

function show_logo()
{
	clear
	print_line
	echo -e "${GREEN}${__appname__[@]:0:1}${RESET}${__appname__[@]:1} V${__version__}"
	echo -e "${GREEN}G${RESET}ithub $url_shell_pkg_manager"
	echo -e "${GREEN}A${RESET}utor $__author__"
	print_line
}

function usage()
{
cat << EOF
   Use:
      -h|--help         Exibe ajuda.
      -v|--version      Exibe versão.

      -c|--configure    Configura este script e suas configurações no sistema.
      -u|--self-update  Instala a ultima versão(online) deste script disponível no github.

      --self-install         Instala este script(offline) no seu sistema.
      -i|--install (módulo)  Instalar um ou mais módulo(s) no sistema.
      -r|--remove (módulo)   Remove um ou mais módulos do seu sistema.

      up|update  Atualiza a lista de scripts disponíveis para instalação.

EOF
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

	local msg="Deseja ${RED}deletar${RESET} os seguintes arquivos/diretórios? : $@ \n${GREEN}s${RESET}/${RED}N${RESET}: "
	if [[ "$CONFIRM" != 'True' ]]; then
		echo -ne "$msg"
		read -n 1 -t 20 yesno
		printf "\n"
		case "$yesno" in 
			s|S|Y|y) ;;
			*) return;;
		esac
	fi

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

function __copy_mod__()
{
	# Copia os módulos.
	echo -ne "Instalando ... $2 "
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

	local url="$1"
	local path_file="$2"

	if [[ -z $Downloader ]]; then
		red "(download): Instale curl|wget|aria2c para prosseguir."
		sleep 0.1
		return 1
	fi

	echo -ne "Conectando aguarde ... "
	if [[ ! -z $path_file ]]; then
		case "$Downloader" in 
			aria2c) 
					aria2c -c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" 1> /dev/null
					;;
			curl)
				curl -C - -S -L -s -o "$path_file" "$url"
					;;
			wget)
				wget -q -c "$url" -O "$path_file"
					;;
		esac
	else
		case "$Downloader" in 
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
	_red '(__download__): ERRO'
}

function _install_modules()
{
	# $1 = modulo(s) a serem instalados.

	print_line
	echo -e "${GREEN}I${RESET}nstalando os seguintes módulos/libs:\n"
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
	cd "$temp_dir"/bash-libs-main || return 1
	cd libs
	
	[[ ! -d $PATH_BASH_LIBS ]] && mkdir $PATH_BASH_LIBS

	while [[ $1 ]]; do
		case "$1" in
			print_text) 
					__copy_mod__ print_text.sh "$PATH_BASH_LIBS"/print_text.sh
					;;
			config_path) 
					__copy_mod__ config_path.sh "$PATH_BASH_LIBS"/config_path.sh
					;;
			os) 
				__copy_mod__ os.sh "$PATH_BASH_LIBS"/os.sh
				;;
			requests)
				__copy_mod__ requests.sh "$PATH_BASH_LIBS"/requests.sh
				;;
			utils)
				__copy_mod__ utils.sh "$PATH_BASH_LIBS"/utils.sh
				;;
			*) 
				_red "pacote indisponivel ... $PKG"
				sleep 0.1
				;;
		esac
		shift
	done
	echo -e "Feito!"
}

function _remove_modules()
{
	print_line
	echo -e "${RED}R${RESET}emovendo os seguintes módulos/libs:\n"
	n=0
	for PKG in "${@}"; do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$PKG "
		n="$(($n + 1))"
	done
	echo

	print_line
	__rmdir__ "$@"
	echo -e "Feito!"
}


function self_update()
{
	# Baixar e instalar a ultima versão deste script disponível no github.
	local url_shm_main='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'
	local temp_file_update=$(mktemp)
	
	__download__ "$url_shm_main" "$temp_file_update" || return 1
	cp "$temp_file_update" "$DIR_BIN"/shm
	chmod +x "$DIR_BIN"/shm
	
	if [[ -x $(command -v shm) ]]; then
		echo "Atualização instalada com sucesso."
		return 0
	else
		_red "ERRO"
		return 1
	fi
}

function self_install()
{
	__copy_mod__ "$__script__" "$DIR_BIN"/shm || return 1
	chmod +x "$DIR_BIN"/shm || return 1
}


function list_modules()
{
	# Listar os módulos disponíveis para instalação.
	n=0
	for MOD in $(cat $MODULES_LIST); do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$MOD "
		n="$(($n + 1))"
	done
	echo
}

function update_modules_list()
{
	# Usar o módulo utils.sh
	clear
	local temp_file_update=$(mktemp)

	cd "$dir_of_project"
	if [[ -f ./libs/utils.sh ]]; then
		source ./libs/utils.sh
	elif [[ -f "$PATH_BASH_LIBS/utils.sh" ]]; then
		source ./libs/utils.sh
	else
		_install_modules utils || return 1
		source "$PATH_BASH_LIBS"/utils.sh
	fi
	
	case "$Downloader" in
		curl) curl -fsSL "$URL_MODULES_LIST" -o "$temp_file_update" &;;
		wget) wget -q "$URL_MODULES_LIST" -O "$temp_file_update" &;;
		aria2c) aria2c "$URL_MODULES_LIST" -d $(dirname "$temp_file_update") -o $(basename "$temp_file_update") 1> /dev/null &;;
	esac	
	wait_pid "$!" "Atualizando a lista de módulos aguarde"

	__copy_mod__ "$temp_file_update" "$MODULES_LIST"
}

_configure()
{
	# Configurações para primeira execução.

	_install_modules config_path || return 1
	update_modules_list || return 1
	source "$PATH_BASH_LIBS"/config_path.sh 2> /dev/null
	backup
	config_bashrc
	config_zshrc

	touch ~/.shmrc
	sed -i '/PATH_BASH_LIBS/d' $FILE_CONFIG
	# grep -q -m 1 "export PATH_BASH_LIBS=" ~/.shmrc && return 0
	echo -e "export PATH_BASH_LIBS=$PATH_BASH_LIBS" >> $FILE_CONFIG
}

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
	# Percorrer todos arguemtos.
	for OPT in "${OptionList[@]}"; do
		if [[ "$OPT" == '--install' ]] || [[ "$OPT" == '-i' ]]; then
			# Verificar quais argumentos vem depois da opção --install.
			# o loop será quebrado quando encontrar outra opção ou seja -- ou -.
			for pkg in "${OptionList[@]:$num}"; do
				if [[ "$pkg" != '--install' ]] && [[ "$pkg" != '-i' ]]; then
					# Verificar se o primeiro caracter e igual a '-'. Se for o loop deve ser
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
			-i|--install) _install_modules "${PkgsList[@]}";;
			-r|--remove) _remove_modules;;
			-c|--configure) _configure;;
			--self-install) self_install;; 
			-u|--self-update) self_update;;
			-l|--list) list_modules;;
			-h|--help) usage; return; break;;
			-v|--version) echo -e "$__version__";;

			up|update) update_modules_list;;
			*) ;;
		esac
		shift
	done
}

if [[ ! -z $1 ]]; then
	main "$@"
else
	show_logo
	self_update # Auto instala esta script em ~/.local/bin/shm
	_configure  # Executa configuração inicial. Ver o arquivo ~/.shmrc 
fi

rm -rf "$temp_dir" 1> /dev/null 2>&1
