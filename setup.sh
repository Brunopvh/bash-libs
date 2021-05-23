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

version='0.1.1'
appname='setup.sh'
author='Bruno Chaves' # https://github.com/Brunopvh

readonly __script__=$(readlink -f "$0")
readonly dir_of_project=$(dirname "$__script__")
clientDownloader=null
DELEY=0.1

# Definir o destino dos módulos e do script shm.
if [[ $(id -u) == 0 ]]; then
	INSTALATION_DIR='/opt'
	DIR_BIN='/usr/local'
	PATH_BASH_LIBS='/usr/local/lib'
else
	INSTALATION_DIR=~/.local/share
	DIR_BIN=~/.local
	PATH_BASH_LIBS=~/.local/lib
fi

# Concatenar os diretórios
INSTALATION_DIR+="/shm-x86_64"
DIR_BIN+="/bin"
PATH_BASH_LIBS+="/bash"

readonly TEMPORARY_DIR=$(mktemp --directory -u) # -u Não cria o diretório.
readonly TEMPORARY_FILE=$(mktemp -u) # -u Não cria o arquivo
readonly DIR_UNPACK="$TEMPORARY_DIR/unpack"
readonly DIR_DOWNLOAD="$TEMPORARY_DIR/download"
readonly URL_RAW_REPO='https://raw.github.com/Brunopvh/bash-libs/main'
readonly URL_PACKAGES_LIBS="https://github.com/Brunopvh/bash-libs/archive/main.tar.gz"
readonly TEMP_FILE_TAR="$DIR_DOWNLOAD/libs.tar.gz"

USER_SHELL=$(basename $SHELL)
if [[ $USER_SHELL == 'zsh' ]]; then
	if [[ $(id -u) == 0 ]]; then
		_shell_config_file='/etc/zsh/zshrc'
	else
		_shell_config_file=~/.zshrc
	fi
elif [[ $USER_SHELL == 'bash' ]]; then
	if [[ $(id -u) == 0 ]]; then
		_shell_config_file='/etc/bash.bashrc'
	else
		_shell_config_file=~/.bashrc
	fi
fi

function usage()
{
cat <<EOF
   Use: install|uninstall|--version|--help
        

   $(basename $appname)     Instala o shm apartir dos arquivos no github (online installer)   

   install         Instalar o shm apartir do diretório do projeto
   uninstall       Desinstala o shm
   -v|--version    Mostra versão
   -h|--help       Mostra ajuda

EOF
}

function msg_erro()
{
	echo -e "ERRO ... $@"
	sleep "$DELEY"
}

function is_shm() 
{
	# Verificar se existe outra versão do shm instalada no sistema.
	if [[ -f "${INSTALATION_DIR}/shm.sh" && -x "${DIR_BIN}/shm" ]]; then
		return 0
	else
		return 1
	fi 

}

function question_install()
{
	# Não  questiona nada pois não exite outras versões do shm instaladas (is_shm retornou 1).
	#if ! is_shm; then return 0; fi 

	# Perguntar se o usuário deseja prossegui com a instalação
	# pois já existe uma versão instalada no sistema (is_shm retornou status 0)
	echo -e "Existe uma versão do shm instalada em ... $(command -v shm)"
	read -p "Deseja substituir a versão instalada pela instalação atual [s/N]?: " -n 1 -t 30 _YESNO
	echo
	case "${_YESNO,,}" in 
		s) return 0;;
		n) return 1;;
		*) msg_erro "digite 's' ou 'n'";;
	esac
	
	return 1
}

function create_dirs()
{
	mkdir -p $TEMPORARY_DIR
	mkdir -p $DIR_UNPACK
	mkdir -p $DIR_DOWNLOAD
	mkdir -p $INSTALATION_DIR
	mkdir -p $INSTALATION_DIR/libs
	mkdir -p $PATH_BASH_LIBS
	mkdir -p $DIR_BIN
}

function clean_dirs()
{
	rm -rf $DIR_UNPACK
	rm -rf $DIR_DOWNLOAD
	rm -rf "$TEMPORARY_DIR"
	rm -rf "$TEMPORARY_FILE" 2> /dev/null
}

function uninstall_shm()
{
	if ! is_shm; then msg_erro "(uninstall_shm) ... shm NÃO está instalado"; return 0; fi

	read -p "Deseja desinstalar shm [s/N]?: " -n 1 -t 30 _YESNO
	echo
	if [[ "${_YESNO,,}" != 's' ]]; then 
		echo "Abortando"
		return 0
	fi

	rm -rf "$INSTALATION_DIR"
	rm -rf "$DIR_BIN/shm"
	echo "shm desinstalado com sucesso."
}

function set_client_downloader()
{
	if [[ -x $(command -v aria2c) ]]; then
		clientDownloader='aria2c'
	elif [[ -x $(command -v wget) ]]; then
		clientDownloader='wget'
	elif [[ -x $(command -v curl) ]]; then
		clientDownloader='curl'
	else
		printf "Instale o curl|wget|aria2 para prosseguir.\n"
		return 1
	fi
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
			msg_erro "o arquivo não existe $1"
		fi
		shift
	done

	[[ "$STATUS_OUTPUT" == 0 ]] && return 0
	return 1
}

function check_internet()
{
	[[ ! -x $(command -v ping) ]] && {
		msg_erro "(check_internet) ... comando ping não instalado."
		return 1
	}

	if ping -c 1 8.8.8.8 1> /dev/null 2>&1; then
		return 0
	else
		msg_erro "você está off-line"
		return 1
	fi
}

function silent_download()
{
	# Baixa arquivos da internet e modo silent/quiet.
	# Requer um gerenciador de downloads wget, curl, aria2
	# 
	# https://curl.se/
	# https://www.gnu.org/software/wget/
	# https://aria2.github.io/manual/pt/html/README.html
	# 
	# $1 = URL
	# $2 = Output File - (Opcional)
	#

	set_client_downloader
	if [[ -f "$2" ]]; then
		echo -e "Arquivo encontrado ... $2"; return 0
	fi

	local url="$1"
	local path_file="$2"

	if [[ "$clientDownloader" == 'null' ]]; then
		msg_erro "(silent_download) Instale curl|wget|aria2c para prosseguir."
		return 1
	fi

	check_internet || return 1
	
	echo -ne "Conectando ... $url "
	if [[ ! -z $path_file ]]; then
		case "$clientDownloader" in 
			aria2c) 
					aria2c -c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" 1> /dev/null 2>&1 
					;;
			curl)
				curl -s -C - -S -L -o "$path_file" "$url"
					;;
			wget)
				wget -q -c "$url" -O "$path_file"
					;;
		esac
	else
		case "$clientDownloader" in 
			aria2c) 
					aria2c -c "$url" 1> /dev/null 2>&1
					;;
			curl)
					curl -s -C - -S -L -O "$url"
					;;
			wget)
				wget -q -c "$url"
					;;
		esac
	fi

	if [[ $? == 0 ]]; then echo "OK"; return 0; fi
	msg_erro "(silent_download)"; return 1
}

function install_shell_package_manager()
{
	# Para que esta função seja executada com sucesso é nescessário que 
	# este arquivo de instalação seja executado apartir da raiz do projeto.
	echo -ne "Instalando libs ... "
	cp -R ./libs/os.sh "$INSTALATION_DIR"/libs/os.sh 1> /dev/null
	cp -R ./libs/utils.sh "$INSTALATION_DIR"/libs/utils.sh 1> /dev/null
	cp -R ./libs/requests.sh "$INSTALATION_DIR"/libs/requests.sh 1> /dev/null
	cp -R ./libs/print_text.sh "$INSTALATION_DIR"/libs/print_text.sh 1> /dev/null
	cp -R ./libs/config_path.sh "$INSTALATION_DIR"/libs/config_path.sh 1> /dev/null
	cp -R ./setup.sh "$INSTALATION_DIR"/setup.sh 1> /dev/null
	cp -R ./libs/modules.list "$INSTALATION_DIR"/libs/modules.list 1> /dev/null
	if [[ $? != 0 ]]; then
		msg_erro "(install_shell_package_manager)"
		return 1
	fi
	echo 'OK'

	echo -ne "Instalando shm em ... $INSTALATION_DIR"
	cp -R shm.sh "$INSTALATION_DIR"/shm.sh
	chmod a+x "$INSTALATION_DIR"/shm.sh
	ln -sf "$INSTALATION_DIR"/shm.sh "$DIR_BIN"/shm
	[[ $? == 0 ]] || return 1
	echo 'OK'
	configure_shell
}

function configure_shell()
{
	grep -q ^"export PATH_BASH_LIBS=$PATH_BASH_LIBS" ~/.shmrc || {
			echo -e "export PATH_BASH_LIBS=$PATH_BASH_LIBS" >> ~/.shmrc
		}

	grep -q "^source .*shmrc" "$_shell_config_file" || {
		echo "source ~/.shmrc 1>/dev/null 2>&1" >> "$_shell_config_file"
		}
}

function online_setup()
{
	# Baixar os arquivos do repositório main.
	create_dirs
	silent_download "$URL_PACKAGES_LIBS" "$TEMP_FILE_TAR" || return 1
	
	cd $DIR_DOWNLOAD
	echo -ne "Descompactando ... "
	tar -zxvf "$TEMP_FILE_TAR" -C "$DIR_UNPACK" 1> /dev/null || return 1
	echo 'OK'
	cd $DIR_UNPACK
	mv $(ls -d bash*) bash-libs
	cd bash-libs
	install_shell_package_manager
	"$DIR_BIN"/shm --configure
}

function offline_setup()
{
	create_dirs
	cd $dir_of_project
	[[ ! -d ./libs ]] && {
		msg_erro "(offline_setup): diretório libs não encontrado em $(pwd)."
		return 1
	}

	[[ ! -f ./shm.sh ]] && {
		msg_erro "(offline_setup): arquivo shm.sh não encontrado em $(pwd)."
		return 1
	}

	# Verificar a existência dos módulos/dependências locais.
	exists_file ./libs/os.sh ./libs/requests.sh ./libs/utils.sh ./libs/print_text.sh ./libs/config_path.sh || return 1
	exists_file ./libs/modules.list || return 1
	install_shell_package_manager
	"$DIR_BIN"/shm --configure
}

function main_setup()
{

	if [[ -z $1 ]]; then
		online_setup
		return 0
	fi

	while [[ $1 ]]; do
		case "$1" in
			install) offline_setup; return 0; break;;
			uninstall) uninstall_shm; return 0; break;;
			-v|--version) echo -e "$version";;
			-h|--help) usage; return 0; break;;
			--module) ;;
			*) msg_erro "parâmetro inválido detectado"; return 1; break;;
		esac
		shift
	done
}


main_setup "$@"
clean_dirs 1> /dev/null 2>&1




