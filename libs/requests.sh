#!/usr/bin/env bash
#
version_requests='2021-02-21'
#
# - REQUERIMENT = print_text
# - REQUERIMENT = utils
# - REQUERIMENT = os
# - CLI_REQUERIMENT = wget|curl|aria2
#
#--------------------------------------------------#
# Instalação dos modulos necessários.
#--------------------------------------------------#
# https://github.com/Brunopvh/bash-libs
# sudo bash -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
# sudo bash -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)"
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

#=============================================================#

export imported_requests='True'

# Verificar gerenciador de downloads.
if [[ -x $(command -v aria2c) ]]; then
	export clientDownloader='aria2c'
elif [[ -x $(command -v wget) ]]; then
	export clientDownloader='wget'
elif [[ -x $(command -v curl) ]]; then
	export clientDownloader='curl'
else
	export clientDownloader='None'
	print_erro "requests.sh ... nenhum gerenciador de downloads foi encontrado no sistema. Instale curl|wget|aria2"
	sleep 1
	exit 1
fi
	

function __ping__()
{
	[[ ! -x $(command -v ping) ]] && {
		print_erro "(__ping__) ... comando ping não instalado."
		return 1
	}

	if ping -c 1 8.8.8.8 1> /dev/null 2>&1; then
		return 0
	else
		print_erro "você está off-line"
		return 1
	fi
}

function http_request()
{
	case "$clientDownloader" in
		curl) curl -A curl -s -S -L "$@";;
		wget) wget -q -O- "$@";;
		aria2c)
				local temp_file=$(mktemp -u)
				aria2c -d $(dirname "$temp_file") -o $(basename "$temp_file") "$@" 1> /dev/null || return 1
				cat "$temp_file"
				rm "$temp_file"
			;;
	esac
	[[ $? == 0 ]] && return 0
	return $?
}

function download()
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

	[[ -f "$2" ]] && {
		blue "Arquivo encontrado ...$2"
		return 0
	}

	local url="$1"
	local path_file="$2"

	if [[ "$clientDownloader" == 'None' ]]; then
		print_erro "(download) Instale curl|wget|aria2c para prosseguir."
		sleep 0.1
		return 1
	fi

	__ping__ || return 1
	echo -e "Conectando ... $url"
	if [[ ! -z $path_file ]]; then
		case "$clientDownloader" in 
			aria2c) 
					aria2c -c "$url" -d "$(dirname $path_file)" -o "$(basename $path_file)" 
					;;
			curl)
				curl -C - -S -L -o "$path_file" "$url"
					;;
			wget)
				wget -c "$url" -O "$path_file"
					;;
		esac
	else
		case "$clientDownloader" in 
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
	print_erro '(download)'
}


gitclone()
{
	# $1 = repos
	# $2 = Output dir - (Opcional)
	#
	[[ ! -x $(command -v git) ]] && {
		red "Necessário instalar o pacote 'git"
		return 1
	}

	[[ -z $2 ]] && {
		red "(gitclone) use: gitclone <repo.git> <output-dir>"
		return 1
	}

	if [[ ! -d "$2" ]]; then
		sred "(gitclone) O diretório não existe ... $2"
		sred "(gitclone) saindo com status 1."
		sleep 1
		return 1
	fi

	if [[ ! -w "$2" ]]; then
		sred "(gitclone) Você não tem permissão de escrita em ... $2"
		sred "(gitclone) saindo com status 1"
		sleep 1
		return 1
	fi

	[[ -d $2 ]] && {
		echo -e  "Entrando no diretório ... $2" 
		cd "$2"
	}

	# Obter o nome do diretório de saida do repositório a ser clonado.
	dir_repo=$(basename "$1" | sed 's/.git//g')
	if [[ -d "$dir_repo" ]]; then
		yellow "Diretório encontrado ... $dir_repo"
		if question "Deseja remover o diretório clonado anteriormente"; then
			export AssumeYes='True'
			__rmdir__ "$dir_repo"
		else
			return 0
		fi
	fi

	blue "Clonando ... $1"
	if ! git clone "$1"; then
		red "(gitclone): falha"
		return 1
	fi
	return 0
}

get_html_file()
{
	# Salava uma página html em um arquivo.
	# $1 = URL
	# $2 = Arquivo de saida.

	[[ "${#@}" == 2 ]] || {
		red "(get_html_file): Argumentos invalidos detectado."
		return 1
	}
	
	if [[ -z $2 ]]; then
		red "(get_html_file): Nenhum arquivo foi passado no argumento '2'."
		return 1
	fi
	
	# Verificar se $1 e do tipo url.
	if ! echo "$1" | egrep '(http:|ftp:|https:)' | grep -q '/'; then
		red "(get_html): url inválida"
		return 1
	fi

	download "$1" "$2" 1> /dev/null 2>&1 || return 1
	return 0
}

get_html_page()
{
	# Baixa uma página da web e retorna o contéudo na saida padrão 'stdout'
	#
	# $1 = url - obrigatório.
	# $2 = filtro a ser aplicado no contéudo html - opcional.
	# 
	# Opções:
	#      --find texto    -> Buscar uma ocorrência de texto.
	#      --finda-ll texto -> Busca todas as ocorrências de texto.
	#

	# Verificar se $1 e do tipo url.
	! echo "$1" | egrep '(http:|ftp:|https:)' | grep -q '/' && {
		red "(_get_html_page): url inválida"
		return 1
	}

	local temp_file_html=$(mktemp); rm -rf "$temp_file_html" 2> /dev/null
	download "$1" "$temp_file_html" 1> /dev/null 2>&1 || return 1

	if [[ "$2" == '--find' ]]; then
		Find="$3"
		grep -m 1 "$Find" "$temp_file_html"
	elif [[ "$2" == '--find-all' ]]; then
		Find="$3"
		grep "$Find" "$temp_file_html"
	else
		cat "$temp_file_html"
	fi
	rm -rf "$temp_file_html" 2> /dev/null
}
