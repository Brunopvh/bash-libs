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
# sudo bash -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
# sudo bash -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
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

readonly __version__='2021-02-27'
readonly __author__='Bruno Chaves'
readonly __appname__='shell-pkg-manager'
readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")
readonly TEMPORARY_DIR=$(mktemp --directory) 
readonly FILE_LIBS_TAR="$TEMPORARY_DIR/bash-libs.tar.gz"
readonly URL_REPO_LIBS_MASTER='https://github.com/Brunopvh/bash-libs/archive/main.tar.gz'
readonly URL_MODULES_LIST='https://raw.github.com/Brunopvh/bash-libs/main/libs/modules.list'
readonly url_shell_pkg_manager='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'

mkdir -p "$TEMPORARY_DIR"

if [[ $(id -u) == 0 ]]; then
	readonly PREFIX='/usr/local/lib'
	DIR_BIN='/usr/local/bin'
	readonly DIR_CONFIG="/etc/${__appname__}"
else
	readonly PREFIX=~/.local/lib
	DIR_BIN=~/.local/bin
	readonly DIR_CONFIG=~/".config/${__appname__}"
fi

readonly FILE_CONFIG=~/.shmrc
readonly MODULES_LIST="$DIR_CONFIG/modules.list"

[[ -f ~/.bashrc ]] && source ~/.bashrc 
[[ -f ~/.shmrc ]] && source ~/.shmrc 2> /dev/null
[[ -z $HOME ]] && HOME=~/
[[ -z $PATH_BASH_LIBS ]] && PATH_BASH_LIBS="$PREFIX"/bash
[[ ! -d $DIR_CONFIG ]] && mkdir $DIR_CONFIG
[[ ! -d $PATH_BASH_LIBS ]] && mkdir $PATH_BASH_LIBS

# Verificar gerenciador de downloads instalado no sistema.
if [[ -x $(command -v aria2c) ]]; then
	clientDownloader='aria2c'
elif [[ -x $(command -v wget) ]]; then
	clientDownloader='wget'
elif [[ -x $(command -v curl) ]]; then
	clientDownloader='curl'
fi

function show_import_erro()
{
	echo "ERRO módulo não encontrado ... $@"
	if [[ -x $(command -v wget) ]]; then
		echo "Execute ... bash -c \"\$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
	elif [[ -x $(command -v curl) ]]; then
		echo "Execute ... bash -c \"\$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)\""
	fi
	sleep 1
	return 1
}

function check_external_modules()
{
	# Verificar se todos os módulos externos necessários estão disponíveis para serem importados.
	[[ ! -f $config_path ]] && { 
		show_import_erro "config_path"; return 1
	}

	[[ ! -f $os ]] && { 
		show_import_erro "os"; return 1 
	}

	[[ ! -f $requests ]] && { 
		show_import_erro "requests"; return 1
	}

	[[ ! -f $utils ]] && { 
		show_import_erro "utils"; return 1 
	}
	
	[[ ! -f $print_text ]]&& {
		show_import_erro "print_text"; return 1
	}

	return 0
}

check_external_modules || {
	# Verificar se os módulos externos estão instalados no sistema.
	cd "$dir_of_project"
	if [[ ! -f setup.sh ]]; then
		chmod +x ./setup.sh
		./setup.sh install || ./setup.sh
	elif [[ -x $(command -v wget) ]]; then
		bash -c "$(wget -q -O- https://raw.github.com/Brunopvh/storecli/master/setup.sh)"
	elif [[ -x $(command -v curl) ]]; then
		bash -c "$(curl -fsSL https://raw.github.com/Brunopvh/storecli/master/setup.sh)"
	else
		echo "Instale curl ou wget"
		exit 1
	fi
	shm update
	exit 1
}


# print_text
[[ $imported_print_text != 'True' ]] && {
	source "$PATH_BASH_LIBS"/print_text.sh 1> /dev/null || exit 1
}

# os
[[ $imported_os != 'True' ]] && {
	source "$PATH_BASH_LIBS"/os.sh 1> /dev/null || exit 1
}


# utils
[[ $imported_utils != 'True' ]] && {
	source "$PATH_BASH_LIBS"/utils.sh 1> /dev/null || exit 1
}

# requests
[[ $imported_requests != 'True' ]] && {
	source "$PATH_BASH_LIBS"/requests.sh 1> /dev/null || exit 1
}

# config_path
[[ $imported_config_path != 'True' ]] && {
	source "$PATH_BASH_LIBS"/config_path.sh 1> /dev/null || exit 1
}


#=============================================================#

# Argumentos/Opções passados na linha de comando.
OptionList=() 

# Lista de pacotes a serem instalados.
PkgsList=()

function show_logo()
{
	clear
	print_line
	echo -e "${CGreen}${__appname__[@]:0:1}${CReset}${__appname__[@]:1} V${__version__}"
	echo -e "${CGreen}G${CReset}ithub $url_shell_pkg_manager"
	echo -e "${CGreen}A${CReset}utor $__author__"
}

function usage()
{
cat << EOF
   Use:
      -h|--help         Exibe ajuda.
      -v|--version      Exibe versão.

      -c|--configure    Configura este script e suas configurações no sistema.
      -u|--self-update  Instala a ultima versão(online) deste script disponível no github.
      -U|--upgrade      Instala a ultima versão (online - github) de um módulo.

      -i|--install (módulo)  Instalar um ou mais módulo(s) no sistema.
      -r|--remove (módulo)   Remove um ou mais módulos do seu sistema.

      --info <module>     Mostra informações sobre um ou mais módulos
      --self-install      Instala este script(offline) no seu sistema.

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

	local msg="Deseja ${CRed}deletar${CReset} os seguintes arquivos/diretórios? : $@ \n${CGreen}s${CReset}/${CRed}N${CReset}: "
	if [[ "$AssumeYes" != 'True' ]]; then
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
			red "Não encontrado ... $1"
		fi
		shift
	done
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

function __copy_mod__()
{
	# Copia os módulos.
	exists_file "$1" || return 1
	echo -ne "Instalando ... $2 "
	if cp -R "$1" "$2"; then
		echo 'OK'
		return 0
	else
		print_erro "$1"
		return 1
	fi
}

function _ping()
{
	[[ ! -x $(command -v ping) ]] && {
		red "(_ping) ERRO ... comando ping não instalado."
		return 1
	}

	if ping -c 2 8.8.8.8 1> /dev/null 2>&1; then
		return 0
	else
		red "ERRO ... você está off-line"
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
	_ping || return 1

	if [[ -z $clientDownloader ]]; then
		red "(download): Instale curl|wget|aria2c para prosseguir."
		sleep 0.1
		return 1
	fi

	echo -ne "Conectando $url aguarde ... "
	if [[ ! -z $path_file ]]; then
		case "$clientDownloader" in 
			aria2c) 
					aria2c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" 1> /dev/null
					;;
			curl)
				curl -S -L -s -o "$path_file" "$url"
					;;
			wget)
				wget -q "$url" -O "$path_file"
					;;
		esac
	else
		case "$clientDownloader" in 
			aria2c) 
					aria2c "$url"
					;;
			curl)
					curl -S -L -O "$url"
					;;
			wget)
				wget "$url"
					;;
		esac
	fi

	[[ $? == 0 ]] && echo 'OK' && return 0
	red '(__download__): ERRO'
}

function install_modules()
{
	# $1 = modulo(s) a serem instalados.
	print_line
	echo -e "${CGreen}I${CReset}nstalando os seguintes módulos/libs:\n"
	n=0
	for PKG in "${@}"; do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$PKG "
		n="$(($n + 1))"
	done
	echo
	
	__download__ "$URL_REPO_LIBS_MASTER" "$FILE_LIBS_TAR" || return 1

	cd "$TEMPORARY_DIR"
	echo -ne "Descompactando ... $FILE_LIBS_TAR "
	tar -zxvf "$FILE_LIBS_TAR" -C "$TEMPORARY_DIR" 1> /dev/null || return 1
	echo 'OK'
	cd "$TEMPORARY_DIR"/bash-libs-main || return 1
	cd libs

	while [[ $1 ]]; do
		local module="$1"
		if [[ -f "$PATH_BASH_LIBS/${module}.sh" ]] && [[ "$Upgrade" == 'True' ]]; then
			echo -ne "Atualizando módulo ... $module ... "
		elif [[ -f "$PATH_BASH_LIBS/${module}.sh" ]]; then
			echo -e "Módulo já instalado ... $module"
			shift
			continue
		fi
		

		if [[ -f "${module}.sh" ]]; then
			__copy_mod__ "${module}.sh" "$PATH_BASH_LIBS/${module}.sh" || { return 1; break; }
			grep -q ^"export readonly $module=$PATH_BASH_LIBS/${module}.sh" ~/.shmrc || {
					echo -e "export readonly $module=$PATH_BASH_LIBS/${module}.sh" >> ~/.shmrc
				}
		else
			red "pacote indisponível ... $module"
			sleep 0.25
		fi
		shift
	done
	echo -e "Feito!"
}

function remove_modules()
{
	print_line
	echo -e "${CRed}R${CReset}emovendo os seguintes módulos/libs:\n"
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

function self_shasum()
{
	sha256sum "$__script__" | cut -d ' ' -f 1
}

function self_update()
{
	if [[ $(id -u) == 0 ]]; then
		DESTINATION_DIR='/usr/local/bin'
	else
		DESTINATION_DIR=~/.local/bin
	fi

	[[ ! -d $DESTINATION_DIR ]] && mkdir $DESTINATION_DIR

	DESTINATION_SCRIPT="$DESTINATION_DIR"/shm
	URL_SCRIPT='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'
	TEMP_SCRIPT=$(mktemp -u)

	printf "Aguarde ... "
	if [[ "$clientDownloader" == 'aria2c' ]]; then
		aria2c "$URL_SCRIPT" -d $(dirname "$TEMP_SCRIPT") -o $(basename "$TEMP_SCRIPT") 1> /dev/null
	elif [[ "$clientDownloader" == 'wget' ]]; then
		wget -q -O "$TEMP_SCRIPT" "$URL_SCRIPT"
	elif [[ "$clientDownloader" == 'curl' ]]; then
		curl -fsSL -o "$TEMP_SCRIPT" "$URL_SCRIPT"
	else
		printf "Instale o curl ou wget para prosseguir.\n"
		exit 1
	fi

	[[ $? == 0 ]] || { red 'ERRO'; return 1; }
	cp -R -u "$TEMP_SCRIPT" "$DESTINATION_SCRIPT" 1> /dev/null
	chmod +x "$DESTINATION_SCRIPT"

	if [[ -x "$DESTINATION_SCRIPT" ]]; then
		echo -e "OK versão ... $(shm -v) instalada com sucesso."
		echo -e "Execute  ... $DESTINATION_SCRIPT --configure"
	else
		printf "Falha"
		exit 1
	fi

	rm -rf "$TEMP_SCRIPT"
}

function self_install()
{
	__copy_mod__ "$__script__" "$DIR_BIN"/shm || return 1
	chmod +x "$DIR_BIN"/shm || return 1
}

function info_mod()
{
	for mod in "${@}"; do
		if grep -q ^"$mod = " "$MODULES_LIST"; then
			grep ^"$mod = " "$MODULES_LIST"
		else
			red "Módulo indisponível ... $mod"
			sleep 0.1
		fi
	done
}

function list_modules()
{
	# Listar os módulos disponíveis para instalação.
	n=0
	for MOD in $(cat $MODULES_LIST | cut -d '=' -f 1); do
		[[ "$n" == 2 ]] && n=0 && echo
		printf "%-20s" "$MOD "
		n="$(($n + 1))"
	done
	echo
}

function update_modules_list()
{
	# Usar o módulo utils.sh
	local temp_file_update=$(mktemp -u); rm -rf $temp_file_update 2> /dev/null
	
	_ping || return 1
	case "$clientDownloader" in
		curl) curl -fsSL "$URL_MODULES_LIST" -o "$temp_file_update" &;;
		wget) wget -q "$URL_MODULES_LIST" -O "$temp_file_update" &;;
		aria2c) aria2c "$URL_MODULES_LIST" -d $(dirname "$temp_file_update") -o $(basename "$temp_file_update") 1> /dev/null &;;
	esac	
	loop_pid "$!" "Atualizando a lista de módulos aguarde"
	__copy_mod__ "$temp_file_update" "$MODULES_LIST"
}

function _configure()
{	
	update_modules_list || return 1
	backup
	config_bashrc
	config_zshrc

	touch ~/.shmrc
	grep -q ^"export readonly PATH_BASH_LIBS=$PATH_BASH_LIBS" ~/.shmrc || {
		echo -e "export readonly PATH_BASH_LIBS=$PATH_BASH_LIBS" >> ~/.shmrc
	}

	#sed -i '/PATH_BASH_LIBS/d' $FILE_CONFIG
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
		elif [[ "$OPT" == '--upgrade' ]] || [[ "$OPT" == '-U' ]]; then
			export Upgrade='True'
		fi

		num="$(($num + 1))"
	done
}

function main()
{
	argument_parse "$@"

	while [[ $1 ]]; do
		case "$1" in
			-i|--install) install_modules "${PkgsList[@]}";;
			-r|--remove) remove_modules;;
			-c|--configure) _configure;;
			-l|--list) list_modules;;
			-u|--self-update) self_update;;
			-h|--help) usage; return; break;;
			-v|--version) echo -e "$__version__";;

			--info) shift; info_mod "$@";;
			--self-install) self_install;;
			--self-shasum) self_shasum;;

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

rm -rf "$TEMPORARY_DIR" 1> /dev/null 2>&1
