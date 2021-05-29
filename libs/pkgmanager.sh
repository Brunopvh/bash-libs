#!/usr/bin/env bash
#
version_pkgmanager='2021-05-29'
#
# - REQUERIMENT = utils
# - REQUERIMENT = print_text
# - REQUERIMENT = os
# - REQUERIMENT = requests
# - CLI_REQUERIMENT = awk
# 
#
#

[[ -z $PATH_BASH_LIBS ]] && source ~/.shmrc

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

# os
[[ $imported_os != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/os.sh 2> /dev/null; then
		show_import_erro "módulo os.sh não encontrado em ... $PATH_BASH_LIBS"
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

# requests
[[ $imported_requests != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/requests.sh 2> /dev/null; then
		show_import_erro "módulo requests.sh não encontrado em ... $PATH_BASH_LIBS"
		exit 1
	fi
}

# platform
[[ $imported_platform != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/platform.sh 2> /dev/null; then
		show_import_erro "módulo platform.sh não encontrado em ... $PATH_BASH_LIBS"
		exit 1
	fi
}

#=============================================================#

export imported_pkgmanager='True'

function is_apt_process()
{
	while true; do
		# Verificar se existe outro processo apt em execução antes de prosseguir com a instalação.
		PidAptInstall=$(ps aux | grep 'root.*apt' | egrep -m 1 '(install|upgrade|update)' | awk '{print $2}')
		PidAptSystemd=$(ps aux | grep 'root.*apt' | egrep -m 1 '(apt.systemd)' | awk '{print $2}')
		PidDpkgInstall=$(ps aux | grep 'root.*dpkg' | egrep -m 1 '(install)' | awk '{print $2}')
		PidPythonAptd=$(ps aux | grep 'root.*apt' | egrep -m 1 '(aptd)' | awk '{print $2}')

		[[ $PidAptInstall != '' ]] && wait_pid $PidAptInstall
		[[ $PidAptSystemd != '' ]] && wait_pid $PidAptSystemd
		[[ $PidDpkgInstall != '' ]] && wait_pid $PidDpkgInstall
		[[ $PidPythonAptd != '' ]] && wait_pid $PidPythonAptd
		break
	done
}

_GDEBI()
{
	is_apt_process

	echo -e "Executando ... sudo gdebi $@"
	if sudo gdebi "$@"; then
		return 0
	else
		red "(_GDEBI) erro: gdebi $@"
		return 1	
	fi	
}

_DPKG()
{
	is_apt_process

	msg "Executando ... sudo dpkg $@"
	if sudo dpkg "$@"; then
		return 0
	else
		sred "(_DPKG): Erro sudo dpkg $@"
		return 1
	fi
}

_APT()
{
	# Antes de proseguir com a instalação devemos verificar se já 
	# existe outro processo de instalação com apt em execução para não
	# causar erros.
	# sudo rm /var/lib/dpkg/lock-frontend 
	# sudo rm /var/cache/apt/archives/lock
	
	is_apt_process
	[[ -f '/var/lib/dpkg/lock-frontend' ]] && sudo rm -rf '/var/lib/dpkg/lock-frontend'
	[[ -f '/var/cache/apt/archives/lock' ]] && sudo rm -rf '/var/cache/apt/archives/lock'

	msg "Executando ... sudo apt $@"
	if sudo apt "$@"; then
		return 0
	else
		sred "(_APT): Erro sudo apt $@"
		return 1
	fi
}

apt_key_add()
{
	is_admin || return 1

	if [[ -f "$1" ]]; then
		printf "(apt_key_add) Adicionando key apartir do arquivo ... $1 "
		sudo apt-key add "$1" || return 1
	else 
		if ! echo "$1" | egrep '(http:|ftp:|https:)' | grep -q '/'; then
			red "(apt_key_add): url inválida $1"
			return 1
		fi

		# Obter key apartir do url $1.
		local TEMP_FILE_KEY=$(mktemp -u) # Não cria o arquivo.

		printf "Adicionando key apartir do url ... $1 "
		download "$1" "$TEMP_FILE_KEY" 1> /dev/null 2>&1 || return 1

		# Adicionar key
		if [[ $? == 0 ]]; then
			sudo apt-key add "$TEMP_FILE_KEY" || return 1
		else
			print_erro ""
			return 1
		fi
		rm -rf "$TEMP_FILE_KEY"
		return 0
	fi
}

add_repo_apt()
{
	# $1 = repositório para adicionar em /etc/apt/sources.list.d/
	# Se o repositório já existir em outro arquivo a adição do repositório
	# será IGNORADA.

	# $2 = Nome do arquivo para gravar o repositório (.list). Se o arquivo já existir
	# a adição do repositório será IGNORADA. 

	# IMPORTANTE: antes de adicionar os repositório, é necessário adicionar o key.pub 
	# de cada repositório adicionado, evitando assim possíveis problemas quando atualizar 
	# o cache do apt (sudo apt update).
	if [[ -z $2 ]]; then
		print_erro "(add_repo_apt): informe um arquivo para adicionar o repositório"
		return 1
	fi

	[[ -f $2 ]] && {
		red "(add_repo_apt) O arquivo já existe ... $2"
		return 1
	}

	local repo="$1"
	local file_repo="$2"

	find /etc/apt -name *.list | xargs grep "^${repo}" 2> /dev/null

	if [[ $? == 0 ]]; then
		print_info "o repositório já existe em /etc/apt pulando."
	else
		print_info "Adicionando repositório em ... $file_repo"
		echo -e "$repo" | sudo tee "$file_repo"
		_APT update || return 1
	fi
	return 0
}


#=============================================================#
# Remover pacotes quebrados em sistemas debian.
#=============================================================#
_BROKE()
{
	if [[ ! -x $(command -v apt 2> /dev/null) ]]; then
		red "(_BROKE) esta opção só está disponível para sistemas baseados em Debian"
		return 0
	fi


	COMMANDS=(
		'sudo dpkg --configure -a'
		'sudo apt clean'
		'sudo apt remove'
		'sudo apt install -y -f'
		)
	if [[ "$OS_ID" == 'debian' ]]; then
		COMMANDS[4]='sudo apt --fix-broken install'
	fi
	
	
	for cmd in "${COMMANDS[@]}"; do
		echo -e "Executando ... $cmd"
		$cmd
	done
	
	# sudo apt install --yes --force-yes -f 
}


_RPM()
{
	echo -e "Executando ... sudo rpm $@"
	if sudo rpm "$@"; then
		return 0
	else
		sred "(_RPM): Erro sudo rpm $@"
		return 1
	fi
}

_DNF()
{
	msg "Executando ... sudo dnf $@"
	if sudo dnf "$@"; then
		return 0
	else
		sred "(_DNF): Erro sudo dnf $@"
		return 1
	fi
}

_rpm_key_add()
{
	is_admin || return 1

	if [[ -f "$1" ]]; then
		printf "(_rpm_key_add) Adicionando key apartir do arquivo ... $1 "
		sudo rpm --import "$1" || return 1
	else 
		if ! echo "$1" | egrep '(http:|ftp:|https:)' | grep -q '/'; then
			red "(apt_key_add): url inválida $1"
			return 1
		fi

		# Obter key apartir do url $1.
		local TEMP_FILE_KEY="$(mktemp -u)"
		printf "Adicionando key apartir do url ... $1 "
		download "$1" "$TEMP_FILE_KEY" 1> /dev/null 2>&1 || return 1 

		if [[ $? == 0 ]]; then
			sudo rpm --import "$TEMP_FILE_KEY" || return 1
			return 0
		else
			print_erro "(_rpm_key_add)"
			return 1
		fi
	fi
}

_addrepo_in_fedora()
{
	# $1 = url do repositório.
	# $2 = Nome do arquivo para gravar o repositório.

	[[ -z $2 ]] && {
		printf "\033[0;31m(_addrepo_in_fedora): informe um arquivo para adicionar o repositório\033[m\n"
		return 1
	}

	# Verificar se $1 e do tipo url.
	! echo "$1" | egrep '(http:|ftp:|https:)' | grep -q '/' && {
		red "(_addrepo_in_fedora): url inválida"
		return 1
	}

	local url_repo="$1"
	local file_repo="$2"
	local temp_file_repo="$(mktemp -u)"

	[[ -f "$file_repo" ]] && {
		print_info "repositório já existe em /etc/yum.repos.d pulando.\n"
		return 0
	}
	
	print_info "adicionando repositório em ... $file_repo\n"
	download "$url_repo" "$temp_file_repo" 1> /dev/null 2>&1 || return 1
	__sudo__ mv "$temp_file_repo" "$file_repo" 
	__sudo__ chown root:root "$file_repo"
	__sudo__ chmod 644 "$file_repo"
	rm -rf "$temp_file_repo" 
	return 0
}

_ZYPPER()
{
	pidZypperInstall=$(ps aux | grep 'root.*zypper' | egrep -m 1 '(install)' | awk '{print $2}')

	# Processo zypper install em execução no sistema.
	while [[ ! -z $pidZypperInstall ]]; do
		wait_pid "$pidZypperInstall"
		pidZypperInstall=$(ps aux | grep 'root.*zypper' | egrep -m 1 '(install)' | awk '{print $2}')
	done

	echo -e "Executando ... sudo zypper $@"
	if sudo zypper "$@"; then
		return 0
	else
		red "(_ZYPPER): Erro sudo zypper $@"
		return 1
	fi
}

_PACMAN()
{
	Pid_Pacman_Install=$(ps aux | grep 'root.*pacman' | egrep -m 1 '(-S|y)' | awk '{print $2}')
	while [[ ! -z $Pid_Pacman_Install ]]; do
		wait_pid "$Pid_Pacman_Install"
		Pid_Pacman_Install=$(ps aux | grep 'root.*pacman' | egrep -m 1 '(-S|y)' | awk '{print $2}')
		sleep 0.2
	done

	echo -e "Executando ... sudo pacman $@"
	if sudo pacman "$@"; then
		return 0
	else
		red "(_PACMAN): Erro sudo pacman $@"
		return 1
	fi
}

_PKG()
{
	# FreeBSD
	Pid_Pkg_Install=$(ps aux | grep 'root.*pkg' | egrep -m 1 '(install|update)' | awk '{print $2}')
	[[ ! -z $Pid_Pkg_Install ]] && wait_pid "$Pid_Pkg_Install"

	echo -e "Executando ... sudo pkg $@"
	if sudo pkg "$@"; then
		return 0
	else
		red "(PKG): Erro sudo pkg $@"
		return 1
	fi
}

_FLATPAK()
{
	if flatpak "$@"; then
		return 0
	else
		red "Falha: flatpak $@"
		return 1
	fi
}


system_pkgmanager()
{
	# Função para instalar os pacotes via linha de comando de acordo 
	# o gerenciador de pacotes de cada sistema.

	#=============================================================#
	# Somente baixar os pacotes caso receber '-d' ou '--downloadonly'
	# na linha de comando ou se a variável AssumeYes for igual a True.
	#=============================================================#
	
	if [[ "$DownloadOnly" == 'True' ]] && [[ "$AssumeYes" == 'True' ]]; then 
		# Somente baixar os pacotes e assumir yes para indagações.
		if [[ $(uname -s) == 'FreeBSD' ]]; then 
			_PKG install -y "$@" || return 1
		elif [[ -f /etc/debian_version ]] && [[ -x $(which apt 2> /dev/null) ]]; then
			_APT install --download-only --yes "$@" || return 1
		elif [[ -f /etc/fedora-release ]] && [[ -x $(which dnf 2> /dev/null) ]]; then
			_DNF install --downloadonly -y "$@" || return 1
		elif [[ "$OS_ID" == 'opensuse-leap' ]] || [[ "$OS_ID" == 'opensuse-tumbleweed' ]]; then
			_ZYPPER download "$@" || return 1
		elif [[ "$OS_ID" == 'arch' ]]; then
			_PACMAN -S --noconfirm --needed --downloadonly "$@" || return 1
		else
			red "(system_pkgmanager) Erro: $@"
			return 1
		fi
		return "$?"
	
	elif [[ "$DownloadOnly" == 'True' ]]; then
		# Somente baixar os pacotes.
		if [[ $(uname -s) == 'FreeBSD' ]]; then 
			_PKG install "$@"
			return 
		fi
		
		case "$OS_ID" in
			debian|ubuntu|linuxmint) _APT install --download-only "$@" || return 1;;
			opensuse-leap|opensuse-tumbleweed) _ZYPPER download "$@" || return 1;;
			fedora) _DNF install --downloadonly "$@" || return 1;;
			arch) _PACMAN -S --needed --downloadonly "$@" || return 1;;
		esac
	elif [[ "$AssumeYes" == 'True' ]]; then 
		# Assumir yes para indagações durante a instalação, equivalênte ao comando
		# apt install -y / aptitude install -y em sistemas debian.
		if [[ $(uname -s) == 'FreeBSD' ]]; then _PKG install -y "$@"; return; fi
		case "$OS_ID" in
			debian|ubuntu|linuxmint) _APT install --yes "$@" || return 1;;
			opensuse-leap|opensuse-tumbleweed) _ZYPPER install -y "$@" || return 1;;
			fedora) _DNF install -y "$@" || return 1;;
			arch) _PACMAN -S --noconfirm --needed "$@" || return 1;;
		esac
	else
		if [[ $(uname -s) == 'FreeBSD' ]]; then _PKG install "$@"; return; fi
		case "$OS_ID" in
			debian|ubuntu|linuxmint) _APT install "$@" || return 1;;
			opensuse-leap|opensuse-tumbleweed) _ZYPPER install "$@" || return 1;;
			fedora) _DNF install "$@" || return 1;;
			arch) _PACMAN -S --needed "$@" || return 1;;
		esac
	fi
}
