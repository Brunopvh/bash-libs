#!/usr/bin/env bash
#
version_requests='2021-02-15'
#
# - REQUERIMENT = print_text
# - REQUERIMENT = utils
# - REQUERIMENT = os
#
#--------------------------------------------------#
# Instalação dos modulos necessários.
#--------------------------------------------------#
# curl -fsSL -o shm.sh https://raw.github.com/Brunopvh/bash-libs/main/shm.sh 
# OU
# wget -q -O shm.sh https://raw.github.com/Brunopvh/bash-libs/main/shm.sh
#
# chmod +x shm.sh 
# ./shm.sh --configure
# ./shm.sh --install print_text utils os
#
#

source ~/.shmrc

# os
if [[ "$lib_os" != 'True' ]]; then
	source "$PATH_BASH_LIBS"/os.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar os.sh"
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

# utils
if [[ "$lib_utils" != 'True' ]]; then
	source "$PATH_BASH_LIBS"/utils.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar utils.sh"
		exit 1
	}
fi

export lib_requests='True'

# Verificar gerenciador de downloads.
if [[ -x $(command -v aria2c) ]]; then
	export clientDownloader='aria2c'
elif [[ -x $(command -v wget) ]]; then
	export clientDownloader='wget'
elif [[ -x $(command -v curl) ]]; then
	export clientDownloader='curl'
else
	export clientDownloader='None'
fi

function __ping__()
{
	[[ ! -x $(command -v ping) ]] && {
		_red "(_ping) ERRO ... comando ping não instalado."
		return 1
	}

	if ping -c 1 8.8.8.8 1> /dev/null 2>&1; then
		return 0
	else
		_red "ERRO ... você está off-line"
		return 1
	fi
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
		red "(download): Instale curl|wget|aria2c para prosseguir."
		sleep 0.1
		return 1
	fi

	__ping__ || return 1
	echo -e "Conectando $url"
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
	red '(download): ERRO'
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

	[[ -z $1 ]] && {
		red "(gitclone) use: gitclone <repo.git>"
		return 1
	}

	if [[ $2 ]] && [[ ! -d "$2" ]]; then
		sred "O diretório não existe ... $2"
		return 1
	fi

	if [[ $2 ]] && [[ ! -w "$2" ]]; then
		sred "Você não tem permissão de escrita em ... $2"
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
			export CONFIRM='True'
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
