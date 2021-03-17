#!/usr/bin/env bash
#
#
version_crypto='2021-03-16'
# - REQUERIMET = print_text
# - REQUERIMET = requests
#
# Instalação do gerenciador de pacotes
#   $ sudo bash -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)"
# Instalação dos módulos:
#   $ shm --install requests print_text
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
	sleep 1
}

# print_text
[[ $imported_print_text != 'True' ]] && {
	if ! source "$PATH_BASH_LIBS"/print_text.sh 2> /dev/null; then
		show_import_erro "módulo print_text.sh não encontrado em ... $PATH_BASH_LIBS"
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

#=============================================================#


gpg_verify()
{
	# $1 = arquivo.asc
	# $2 = arquivo a ser verificado.
	echo -ne "Verificando integridade do arquivo ... $(basename $2) "
	gpg --verify "$1" "$2" 1> /dev/null 2>&1
	if [[ $? == 0 ]]; then  
		echo "OK"
		return 0
	else
		print_erro ""
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
		download "$1" "$TempFileAsc" 1> /dev/null 2>&1 || return 1
			
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


__shasum__()
{
	# Esta função compara a hash de um arquivo local no disco com
	# uma hash informada no parametro "$2" (hash original). 
	#   Ou seja "$1" é o arquivo local e "$2" é uma hash
	local hash_file=''
	if [[ ! -f "$1" ]]; then
		red "(__shasum__) arquivo inválido: $1"
		return 1
	fi

	if [[ -z "$2" ]]; then
		red "(__shasum__) use: __shasum__ <arquivo> <hash>"
		return 1
	fi

	# Calucular o tamanho do arquivo
	len_file=$(du -hs $1 | awk '{print $1}')

	printf "Gerando hash do arquivo ... $1 $len_file\n"
	hash_file=$(sha256sum "$1" | cut -d ' ' -f 1)
	printf "%-15s%65s\n" "HASH original" "$2"
	printf "%-15s%65s\n" "HASH local" "$hash_file"
	printf "Comparando valores "
	if [[ "$hash_file" == "$2" ]]; then
		syellow 'OK'
		return 0
	else
		print_erro ""
		red "(__shasum__): removendo arquivo inseguro ... $1"
		rm -rf "$1"
		return 1
	fi
}