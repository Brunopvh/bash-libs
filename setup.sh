#!/usr/bin/env bash
#
version='2021-02-15'
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
TEMP_SCRIPT=$(mktemp)
rm -rf "$TEMP_SCRIPT"

printf "Aguarde ... "
if [[ -x $(command -v aria2c) ]]; then
	aria2c "$URL_SCRIPT" -d $(dirname "$TEMP_SCRIPT") -o $(basename "$TEMP_SCRIPT") 1> /dev/null
elif [[ -x $(command -v wget) ]]; then
	wget -q -O "$TEMP_SCRIPT" "$URL_SCRIPT"
elif [[ -x $(command -v curl) ]]; then
	curl -fsSL -o "$TEMP_SCRIPT" "$URL_SCRIPT"
else
	printf "Instale o curl ou wget para prosseguir.\n"
	exit 1
fi

cp -R -u -v "$TEMP_SCRIPT" "$DESTINATION_SCRIPT"
chmod +x "$DESTINATION_SCRIPT"

if [[ -x "$DESTINATION_SCRIPT" ]]; then
	printf "OK\n"
	echo -e "Execute  ... $DESTINATION_SCRIPT --configure"
else
	printf "Falha"
	exit 1
fi

rm -rf "$TEMP_SCRIPT"
exit 0
