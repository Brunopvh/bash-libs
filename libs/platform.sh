#!/usr/bin/env bash
#

export version_platform='20201-03-01'
export KERNEL_TYPE=$(uname -s)
export OS_ARCH='None'
export OS_ID='None'
export OS_RELEASE='None'
export VERSION_ID='None'
export VERSION_CODENAME='None'

if uname -m | grep -q "64$"; then
	OS_ARCH='x86_64'
elif uname -m | grep -q "86$"; then
	OS_ARCH='i386'
else
	OS_ARCH='None'
	echo "(platform) ERRO: OS_ARCH não dectectado."
fi


if [[ -f '/usr/local/etc/os-release' ]]; then
	file_release='/usr/local/etc/os-release'
elif [[ -f '/etc/os-release' ]]; then
	file_release='/etc/os-release'
else
	echo "(platform) ERRO: arquivo os-release não encontrado"
	sleep 1
	exit 1
fi


# OS_ID
if [[ $KERNEL_TYPE == 'FreeBSD' ]]; then
	OS_ID=$(uname -r)
elif [[ $KERNEL_TYPE == 'Linux' ]]; then
	OS_ID=$(grep '^ID=' "$file_release" | sed 's/.*=//g;s/\"//g') # debian/ubuntu/linuxmint/fedora ...
fi

# VERSION_ID
if [[ "$file_release" ]]; then
	VERSION_ID=$(grep -m 1 '^VERSION_ID=' "$file_release" | sed 's/.*VERSION_ID=//g;s/\"//g')
elif [[ "$KERNEL_TYPE" == 'FreeBSD' ]]; then
	VERSION_ID=$(uname -r)
fi

# OS_RELEASE
if [[ "$file_release" ]]; then
	OS_RELEASE=$(grep -m 1 '^VERSION=' "$file_release" | sed 's/.*VERSION=//g;s/\"//g;s/(//g;s/)//g;s/ //g')
fi


if [[ -f /etc/debian_version ]] && [[ -x $(command -v apt) ]]; then
	BASE_DISTRO='debian'
elif [[ -f /etc/fedora-release ]] && [[ -x $(command -v dnf) ]]; then
	BASE_DISTRO='fedora'
else
	BASE_DISTRO='None'
fi

function set_version_codename()
{	
	# Codename
	if [[ "$file_release" ]] && [[ $(grep '^VERSION_CODENAME=' "$file_release") ]]; then
		VERSION_CODENAME=$(grep -m 1 '^VERSION_CODENAME=' "$file_release" | sed 's/.*VERSION_CODENAME=//g')
	fi
}

function show_platform_info()
{
	# Exibir informações básicas dos sitema operacional no stdout
	printf "%-20s%-10s\n" "OS_ID" "$OS_ID"
	printf "%-20s%-10s\n" "VERSION_ID" "$VERSION_ID"
	printf "%-20s%-10s\n" "VERSION_CODENAME" "$VERSION_CODENAME"
	printf "%-20s%-10s\n" "OS_RELEASE" "$OS_RELEASE"
	printf "%-20s%-10s\n" "KERNEL_TYPE" "$KERNEL_TYPE"
	printf "%-20s%-10s\n" "OS_ARCH" "$OS_ARCH"
	printf "%-20s%-10s\n" "BASE_DISTRO" "$BASE_DISTRO"
}


set_version_codename
