#!/usr/bin/env bash
#
version_print_text='2021-02-20'
lib_print_text='True'

#=============================================================#
# Cores.
#=============================================================#
# Regular Text
CRed="\033[0;31m"
CGreen="\033[0;32m"
CYellow="\033[0;33m"
CBlue="\033[0;34m"
CPrurple="\033[0;35m"
CCyan="\033[0;36m"
CGray="\033[0;37m"
CWhite="\033[0;37m"
CReset="\033[0m"

# [S] - Strong text (bold)
CSRed="\033[1;31m"
CSGreen="\033[1;32m"
CSYellow="\033[1;33m"
CSBlue="\033[1;34m"
CSPurple="\033[1;35m"
CSCyan="\033[1;36m"
CSGray="\033[1;37m"
CSWhite="\033[1;37m"

# [D] - Dark text
CDRed="\033[2;31m"
CDGreen="\033[2;32m"
CDYellow="\033[2;33m"
CDBlue="\033[2;34m"
CDPurple="\033[2;35m"
CDCyan="\033[2;36m"
CDGray="\033[2;37m"
CDWhite="\033[2;37m"

# [I] Italicized text
CIRed="\033[3;31m"
CIGreen="\033[3;32m"
CIYellow="\033[3;33m"
CIBlue="\033[3;34m"
CIPurple="\033[3;35m"
CICyan="\033[3;36m"
CIGray="\033[3;37m"
CIWhite="\033[3;37m"

# [U] - Underlined text
CURed="\033[4;31m"
CUGreen="\033[4;32m"
CUYellow="\033[4;33m"
CUBlue="\033[4;34m"
CUPurple="\033[4;35m"
CUCyan="\033[4;36m"
CUGray="\033[4;37m"
CUWhite="\033[4;37m"

# [B] - Blinking text
CBRed="\033[5;31m"
CBGreen="\033[5;32m"
CBYellow="\033[5;33m"
CBBlue="\033[5;34m"
CBPurple="\033[5;35m"
CBCyan="\033[5;36m"
CBGray="\033[5;37m"
CBWhite="\033[5;37m"


#=============================================================#
# Imprimir textos com formatação e cores.
#=============================================================#

# Calcular os pixel da janela de terminal.
if [[ -x $(command -v tput 2> /dev/null) ]]; then
	COLUMNS=$(tput cols)
else
	COLUMNS='40'
fi

print_line()
{
    if [[ -z $1 ]]; then
	    printf "%$(tput cols)s\n" | tr ' ' '-'
	else
	    printf "%$(tput cols)s\n" | tr ' ' "$1"
	fi
}

print_erro()
{
	if [[ -z $1 ]]; then
		echo -e "${CRed}ERRO${CReset}"
	else
		echo -e "${CRed}ERRO:${CReset} $@"
	fi
}

print_info()
{
	echo -e "${CGreen}INFO ... ${CReset}$@"
}

msg()
{
	print_line
	echo -e " $@"
	print_line
}

red()
{
	echo -e "${CRed} ! ${CReset}$@"
}

green()
{
	echo -e "${CGreen} + ${CReset}$@"
}

yellow()
{
	echo -e "${CYellow} + ${CReset}$@"
}

blue()
{
	echo -e "${CBlue} + ${CReset}$@"
}

white()
{
	echo -e "${CWhite} + ${CReset}$@"
}

sred()
{
	echo -e "${CSRed}$@${CReset}"
}

sgreen()
{
	echo -e "${CSGreen}$@${CReset}"
}

syellow()
{
	echo -e "${CSYellow}$@${CReset}"
}

sblue()
{
	echo -e "${CSBlue}$@${CReset}"
}



