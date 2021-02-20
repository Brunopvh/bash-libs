#!/usr/bin/env bash
#
version_pkgmanager='2021-02-14'
#
# - REQUERIMENT = utils
# - REQUERIMENT = print_text
# - REQUERIMENT = awk
# 
#
#

[[ $PATH_BASH_LIBS ]] && source ~/.shmrc 2> /dev/null

# os
if [[ "$lib_os" != 'True' ]]; then
	source "$os" 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar os.sh"
		exit 1
	}
fi

# print_text
if [[ "$lib_print_text" != 'True' ]]; then
	source "$print_text" 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar print_text.sh"
		exit 1
	}
fi

# utils
if [[ "$lib_utils" != 'True' ]]; then
	source "$utils" 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar utils.sh"
		exit 1
	}
fi

# requests
if [[ "$lib_requests" != 'True' ]]; then
	source "$requests" 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar requests.sh"
		exit 1
	}
fi

export lib_pkgmanager='True'

function is_apt_process()
{
	# Verificar se existe outro processo apt em execução antes de prosseguir com a instalação.
	PidAptInstall=$(ps aux | grep 'root.*apt' | egrep -m 1 '(install|upgrade|update)' | awk '{print $2}')
	Pid_Apt_Systemd=$(ps aux | grep 'root.*apt' | egrep -m 1 '(apt.systemd)' | awk '{print $2}')
	PidDpkgInstall=$(ps aux | grep 'root.*dpkg' | egrep -m 1 '(install)' | awk '{print $2}')
	PidPythonAptd=$(ps aux | grep 'root.*apt' | egrep -m 1 '(aptd)' | awk '{print $2}')

	while [[ ! -z $PidAptInstall ]]; do
		wait_pid "$PidAptInstall"
		sleep 0.1
		PidAptInstall=$(ps aux | grep 'root.*apt' | egrep -m 1 '(install|upgrade|update)' | awk '{print $2}')
	done


	while [[ ! -z $Pid_Apt_Systemd ]]; do 
		wait_pid "$Pid_Apt_Systemd"
		Pid_Apt_Systemd=$(ps aux | grep 'root.*apt' | egrep -m 1 '(apt.systemd)' | awk '{print $2}')
		sleep 0.2
	done
	
	while [[ ! -z $PidDpkgInstall ]]; do 
		wait_pid "$PidDpkgInstall"
		PidDpkgInstall=$(ps aux | grep 'root.*dpkg' | egrep -m 1 '(install)' | awk '{print $2}')
		sleep 0.2
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
		download "$1" "$TEMP_FILE_KEY" 1> /dev/null || return 1

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

	# $2 = Nome do arquivo para gravar o repositório. Se o arquivo já existir
	# a adição do repositório será IGNORADA. 

	# IMPORTANTE antes de adicionar os repositório, e necessário adicionar key.pub 
	# para cada repositório, para evitar problemas quando atualizar o cache do apt (sudo apt update)
	if [[ -z $2 ]]; then
		sred "(add_repo_apt): informe um arquivo para adicionar o repositório"
		return 1
	fi

	local repo="$1"
	local file_repo="$2"

	find /etc/apt -name *.list | xargs grep "^${repo}" 2> /dev/null
	if [[ $? == 0 ]] || [[ -f "$file_repo" ]]; then
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

	
	yellow "Executando: dpkg --configure -a"
	_DPKG --configure -a

	yellow "Executando: apt clean"
	_APT clean

	yellow "Executando: apt remove"
	_APT remove
	
	yellow "Executando: apt install -y -f"
	_APT install -y -f

	yellow "Executando: apt --fix-broken install"
	_APT --fix-broken install
	
	# sudo apt install --yes --force-yes -f 
}


_RPM()
{
	_print "Executando ... sudo rpm $@"
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
		local TEMP_FILE_KEY="$(mktemp)_rpm_key_add.key"

		printf "Adicionando key apartir do url ... $1 "
		download "$1" "$TEMP_FILE_KEY" 1> /dev/null || return 1 

		if [[ $? == 0 ]]; then
			sudo rpm --import "$TEMP_FILE_KEY" || return 1
			return 0
		else
			printf "${CRed}FALHA no download${CReset}\n"
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
	local temp_file_repo="$(mktemp)_yum.repo"

	[[ -f "$file_repo" ]] && {
		printf "${CGreen}INFO${CReset} ... repositório já existe em /etc/yum.repos.d pulando.\n"
		return 0
	}
	
	printf "${CGreen}A${CReset}dicionando repositório em ... $file_repo\n"
	download "$url_repo" "$temp_file_repo" 1> /dev/null || return 1
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

	_print "Executando ... sudo zypper $@"
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

	_print "Executando ... sudo pacman $@"
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

	_print "Executando ... sudo pkg $@"
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
