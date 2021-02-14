#!/usr/bin/env bash
#
# Este script serve para inserir os diretórios que contém binário na
# HOME('~/.local/bin') na variável PATH do usuario atual.
#
version_config_path='2021-02-13'
#
export lib_config_path='True'

bash_config=~/.bashrc
zsh_config=~/.zshrc

# Inserir ~/.local/bin em PATH.
echo "$PATH" | grep -q "$HOME/.local/bin" || {
	PATH="$HOME/.local/bin:$PATH"
}

config_bashrc()
{
	[[ $(id -u) == 0 ]] && return
	touch "$bash_config"
	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" "$bash_config" 1> /dev/null && return 0

	echo "Configurando o arquivo ... $bash_config"
	sed -i "/^export.*PATH=.*:/d" "$bash_config"
	echo "export PATH=$PATH" >> "$bash_config"
	echo "Execute ... source $bash_config OU reinicie o shell"
}

config_zshrc()
{
	[[ $(id -u) == 0 ]] && return
	[[ ! -x $(command -v zsh) ]] && return 0
	touch "$zsh_config"

	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" "$zsh_config" 1> /dev/null && return 0

	echo "Configurando o arquivo ... $zsh_config"
	sed -i "/^export.*PATH=.*:/d" "$zsh_config"
	echo "export PATH=$PATH" >> "$zsh_config"
	echo "Execute ... source $zsh_config OU reinicie o shell"
}

backup()
{
	[[ $(id -u) == 0 ]] && return
	# ~/.bashrc
	if [ -f "$bash_config" ]; then
		if [ ! -f ~/.bashrc.backup ]; then
			echo -e "\e[5;33mC\e[mriando backup do arquivo ... $bash_config => ~/.bashrc.backup"
			cp "$bash_config" ~/.bashrc.backup
			sleep 1
		fi
	fi

	# ~/.zshrc
	if [ -f "$zsh_config" ]; then
		if [ ! -f ~/.zshrc.backup ]; then
			echo -e "\e[5;33mC\e[mriando backup do arquivo ... $zsh_config => ~/.zshrc.backup"
			cp "$zsh_config" ~/.zshrc.backup
			sleep 1
		fi
	fi
}



