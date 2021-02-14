#!/usr/bin/env bash
#
#
# - REQUERIMET = print_text
# - REQUERIMET = requests
#
# Instalação do gerenciador de pacotes
#   $ sudo sh -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)"
# Instalação dos módulos:
#   $ shm --install requests print_text
#


[[ -z $PATH_BASH_LIBS ]] && source ~/.shmrc

# requests
if [[ "$lib_requests" != 'True' ]]; then
	source "$PATH_BASH_LIBS"/requests.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar requests.sh"
		exit 1
	}
fi

# print_text
if [[ "$lib_print_text" != 'True' ]]; then
	source "$PATH_BASH_LIBS"/print_text.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar print_text.sh"
		exit 1
	}
fi

gpg_verify()
{
	echo -ne "Verificando integridade do arquivo ... $(basename $2) "
	gpg --verify "$1" "$2" 1> /dev/null 2>&1
	if [[ $? == 0 ]]; then  
		echo "OK"
		return 0
	else
		sred "ERRO"
		sleep 1
		return 1
	fi
}

gpg_import()
{
	# Função para importar uma chave com o comando gpg --import <file>
	# esta função também suporta informar um arquivo remoto ao invés de um arquivo
	# no armazenamento local.
	# EX:
	#   gpg_import url
	#   gpg_import file
	
	[[ -z $1 ]] && {
		sred "(gpg_import): opção incorreta detectada. Use gpg_import <file> | gpg_import <url>"
	}

	if [[ -f "$1" ]]; then
		printf "Importando apartir do arquivo ... $1 "
		if gpg --import "$1" 1> /dev/null 2>&1; then
			echo "OK"
			return 0
		else
			sred "ERRO"
			return 1
		fi
	else
		# Verificar se $1 e do tipo url ou arquivo remoto
		if ! echo "$1" | egrep '(http|ftp)' | grep -q '/'; then
			red "(gpg_import): url inválida"
			return 1
		fi
		
		local TempFileAsc="$(mktemp)_gpg_import"
		printf "Importando key apartir da url ... $1 "
		download "$1" "$TempFileAsc" 1> /dev/null || return 1
			
		# Importar Key
		if gpg --import "$TempFileAsc" 1> /dev/null 2>&1; then
			syellow "OK"
			rm -rf "$TempFileAsc"
			return 0
		else
			sred "ERRO"
			rm -rf "$TempFileAsc"
			return 1
		fi
	fi
}
