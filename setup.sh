#!/usr/bin/env bash
#
# Script para automatizar a instalação do gerenciador shm(Shell Package Manager).
#
# INSTALAÇÃO OFFLINE: chmod +x setup.sh; ./setup.sh
#
# INSTALAÇÃO ONLINE: sudo sh -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#                    sudo sh -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
#

if [[ $(id -u) == 0 ]]; then
	DESTINATION_DIR='/usr/local/bin'
else
	DESTINATION_DIR=~/.local/bin
fi

[[ ! -d $DESTINATION_DIR ]] && mkdir $DESTINATION_DIR

DESTINATION_SCRIPT="$DESTINATION_DIR"/shm
URL_SCRIPT='https://raw.github.com/Brunopvh/bash-libs/main/shm.sh'

printf "Aguarde ... "
if [[ -x $(command -v wget) ]]; then
	wget -q -O "$DESTINATION_SCRIPT" "$URL_SCRIPT"
elif [[ -x $(command -v curl) ]]; then
	curl -fsSL -o "$DESTINATION_SCRIPT" "$URL_SCRIPT"
else
	printf "Instale o curl ou wget para prosseguir.\n"
	exit 1
fi

chmod +x "$DESTINATION_SCRIPT"
if [[ -x "$DESTINATION_SCRIPT" ]]; then
	printf "OK\n"
	echo -e "Execute  ... $DESTINATION_SCRIPT --configure"
else
	printf "Falha"
	exit 1
fi

exit 0
