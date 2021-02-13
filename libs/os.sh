#!/usr/bin/env bash
#
__version__='2021-02-13'
# - REQUERIMENT = print_text
# - REQUERIMENT = utils
#

[[ -z $PATH_BASH_LIBS ]] && {
	if [[ -f ~/.shmrc ]]; then
		source ~/.shmrc
	else
		echo -e "ERRO: não foi possivel importar print_text.sh"
		exit 1
	fi
}

[[ "$lib_print_text" != 'True' ]] && {
	source "$PATH_BASH_LIBS"/print_text.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar print_text.sh"
		exit 1
	}
}


[[ "$lib_utils" != 'True' ]] && {
	source "$PATH_BASH_LIBS"/utils.sh 2> /dev/null || {
		echo -e "ERRO: não foi possivel importar utils.sh"
		exit 1
	}
}

export lib_os='True'

if [[ $(id -u) == 0 ]]; then
	export readonly DIR_ROOT_BIN='/usr/local/bin'
	export readonly DIR_ROOT_LIB='/usr/local/lib'
else
	export readonly DIR_USER_BIN=~/.local/bin
	export readonly DIR_USER_LIB=~/.local/lib
fi

wait_pid()
{
	# Esta função serve para executar um loop enquanto um determinado processo
	# do sistema está em execução, por exemplo um outro processo de instalação
	# de pacotes, como o "apt install" ou "pacman install" por exemplo, o pid
	# deve ser passado como argumento $1 da função. Enquanto esse processo existir
	# o loop ira bloquar a execução deste script, que será retomada assim que o
	# processo informado for encerrado.
	local array_chars=('\' '|' '/' '-')
	local num_char='0'
	local Pid="$1"

	while true; do
		ALL_PROCS=$(ps aux)
		if [[ $(echo -e "$ALL_PROCS" | grep -m 1 "$Pid" | awk '{print $2}') != "$Pid" ]]; then 
			break
		fi

		Char="${array_chars[$num_char]}"		
		echo -ne "Aguardando processo com pid [$Pid] finalizar [${Char}]\r" # $(date +%H:%M:%S)
		sleep 0.15
		num_char="$(($num_char+1))"
		[[ "$num_char" == '4' ]] && num_char='0'
	done
	echo -e "Aguardando processo com pid [$Pid] ${CYellow}finalizado${CReset} [${Char}]"	
}

is_admin(){
	printf "Autênticação necessária para prosseguir "
	if [[ $(sudo id -u) == 0 ]]; then
		printf "OK\n"
		return 0
	else
		sred "ERRO"
		return 1
	fi
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

	local msg="Deseja ${CRed}deletar${CReset} os seguintes arquivos/diretórios? : $@\n"
	question "$msg" || return 1

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

function __copy__()
{
	echo -ne "Copiando ... $1 "
	if cp -R "$1" "$2"; then
		echo 'OK'
		return 0
	else
		_red "Falha"
		return 1
	fi
}

get_type_file()
{
	# Usar o comando "file" para obter o cabeçalho de um arquivo qualquer.
	[[ -z $1 ]] && return 1
	[[ -x $(command -v file) ]] file || {
		echo 'None'
		return 1
	}

	file "$1" | cut -d ' ' -f 2
}

unpack_archive()
{
	# $1 = arquivo a ser descomprimido - (obrigatório)
	# $2 = diretório de saida - (opcional)

	[[ ! -f "$1" ]] && {
		red "(_unpack): nenhum arquivo informado no parâmetro 1."
		return 1
	}

	if [[ "$2" ]]; then 
		DirUnpack="$2"
	elif [[ -z "$DirUnpack" ]]; then
		DirUnpack=$(pwd)
	fi

	[[ ! -w "$DirUnpack" ]] && 
		red "Você não tem permissão de escrita [-w] em ... $DirUnpack"
		return 1	
	}

	#printf "Entrando no diretório ... $DirUnpack\n"; cd "$DirUnpack"
	
	path_file="$1"
	if [[ -x $(command -v file) ]]; then
		# Detectar o tipo de arquivo com o comando file.
		extension_file=$(get_type_file "$path_file")
	else
		# Detectar o tipo de arquivo apartir da extensão.
		if [[ "${path_file: -6}" == 'tar.gz' ]]; then    # tar.gz - 6 ultimos caracteres.
			extension_file='gzip'
		elif [[ "${path_file: -7}" == 'tar.bz2' ]]; then # tar.bz2 - 7 ultimos carcteres.
			extension_file='bzip2'
		elif [[ "${path_file: -6}" == 'tar.xz' ]]; then  # tar.xz
			extension_file='XZ'
		elif [[ "${path_file: -4}" == '.zip' ]]; then    # .zip
			extension_file='Zip'
		elif [[ "${path_file: -4}" == '.deb' ]]; then    # .deb
			extension_file='Debian'
		else
			printf "${CRed}(_unpack): Arquivo não suportado ... $path_file${CReset}\n"
			return 1
		fi
	fi

	# Calcular o tamanho do arquivo
	local len_file=$(du -hs $path_file | awk '{print $1}')
	
	# Descomprimir de acordo com cada extensão de arquivo.	
	if [[ "$extension_file" == 'gzip' ]]; then
		tar -zxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'bzip2' ]]; then
		tar -jxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'XZ' ]]; then
		tar -Jxf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'Zip' ]]; then
		unzip "$path_file" -d "$DirUnpack" 1> /dev/null 2>&1 &
	elif [[ "$extension_file" == 'Debian' ]]; then
		
		if [[ -f /etc/debian_version ]]; then    # Descompressão em sistemas DEBIAN
			ar -x "$path_file" 1> /dev/null 2>&1  &
		else                                     # Descompressão em outros sistemas.
			ar -x "$path_file" --output="$DirUnpack" 1> /dev/null 2>&1 &
		fi
	fi

	# echo -e "$(date +%H:%M:%S)"
	wait_pid "$!" "Descompactando ... [$extension_file] ... $(basename $path_file) em ... $DirUnpack"
	return 0
}
