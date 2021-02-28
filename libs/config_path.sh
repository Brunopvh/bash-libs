#!/usr/bin/env bash
#
# Este script serve para inserir os diretórios que contém binário na
# HOME('~/.local/bin') na variável PATH do usuario atual.
#
version_config_path='2021-02-13'
#
export imported_config_path='True'


# Inserir ~/.local/bin em PATH.
echo "$PATH" | grep -q "$HOME/.local/bin" || {
	PATH="$HOME/.local/bin:$PATH"
}

config_bashrc()
{
	[[ $(id -u) == 0 ]] && return
	touch ~/.bashrc
	
	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" ~/.bashrc 1> /dev/null && return 0
	[[ ! -f ~/.bashrc.bak ]] && cp ~/.bashrc ~/.bashrc.bak 1> /dev/null

	echo "Configurando o arquivo ... ~/.bashrc"
	sed -i "/^export.*PATH=.*:/d" ~/.bashrc
	echo "export PATH=$PATH" >> ~/.bashrc
	echo "Execute ... source ~/.bashrc OU reinicie o shell"
	sleep 0.5
}

config_zshrc()
{
	[[ $(id -u) == 0 ]] && return
	if [[ -x $(command -v zsh) ]]; then
		touch ~/.zshrc
	else
		return 0
	fi
	
	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" ~/.zshrc 1> /dev/null && return 0
	[[ ! -f ~/.zshrc.bak ]] && cp ~/.zshrc ~/.zshrc.bak 1> /dev/null

	echo "Configurando o arquivo ... ~/.zshrc"
	sed -i "/^export.*PATH=.*:/d" ~/.zshrc
	echo "export PATH=$PATH" >> ~/.zshrc
	echo "Execute ... source ~/.zshrc OU reinicie o shell"
	sleep 0.5
}



