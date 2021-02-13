#!/usr/bin/env bash
#
__version__='2021-02-13'
#
# - REQUERIMENT = print_text
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
	source "$PATH_BASH_LIBS"/print_text.sh || echo -e "ERRO: não foi possivel importar print_text.sh"
}

export readonly lib_utils='True'

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
	[[ "$CONFIRM" == 'True' ]] && return 0
		
	echo -ne "$@ ${CGreen}s${CReset}/${CRed}N${CReset}?: "
	read -t 15 -n 1 yesno
	echo ' '

	case "${yesno,,}" in
		s|y) return 0;;
		*) printf "${CRed}Abortando${CReset}\n"; return 1;;
	esac
}
