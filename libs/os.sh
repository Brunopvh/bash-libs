#!/usr/bin/env bash
#
__version__='2021-02-11'
# Requer a lib print_text

[[ -f ~/.shmrc ]] && source ~/.shmrc
[[ "$lib_print_text" != 'True' ]] && {
	source "$PATH_BASH_LIBS"/print_text.sh || echo -e "Erro: não foi possivel importar print_text.sh"
}

export lib_os='True'
export readonly DIR_USER_BIN=~/.local/bin
export readonly DIR_USER_LIB=~/.local/lib

question()
{
	# Será necessário indagar o usuário repetidas vezes durante a execução
	# do programa, em que a resposta deve ser do tipo SIM ou NÃO (s/n)
	# esta função automatiza as indagações.
	#
	#   se teclar "s" -----------------> retornar 0  
	#   se teclar "n" ou nada ---------> retornar 1.
	#
	# $1 = Mensagem a ser exibida para o usuário, a resposta deve ser SIM ou NÃO (s/n).
	
	# O usuário não deve ser indagado caso a opção "-y" ou --yes esteja presente 
	# na linha de comando. Nesse caso a função irá retornar '0' como se o usuário estivesse
	# aceitando todas as indagações.
	[[ "$AssumeYes" == 'True' ]] && return 0
		
	printf "$@ ${CYellow}s${CReset}/${CRed}N${CReset}?: "
	read -t 15 -n 1 sn
	echo ' '

	if [[ "${sn,,}" == 's' ]]; then
		return 0
	else
		printf "${CRed}Abortando${CReset}\n"
		return 1
	fi
}

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
