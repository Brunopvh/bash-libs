#!/bin/sh
#
# Este script serve para inserir os diretórios que contém binário na
# HOME('~/bin' e '~/.local/bin') na variável PATH do usuario atual.
#
__version__='2021-01-31'
#

# NÃO pode ser root.
[ $(id -u) -eq 0 ] && {
	echo "\033[1;31mVocê NÃO pode ser o [root] para executar esse programa\033[m"
	exit 1
}

KERNEL_TYPE=$(uname -s)
bash_config=~/.bashrc
zsh_config=~/.zshrc

touch "$bash_config"
touch "$zsh_config"

# Inserir ~/.local/bin em PATH.
echo "$PATH" | grep -q "$HOME/.local/bin" || {
	PATH="$HOME/.local/bin:$PATH"
}

config_bashrc()
{
	# Criar o arquivo ~/.bashrc se não existir
	if [ ! -f "$bash_config" ]; then
		echo ' ' >> "$bash_config"
	fi

	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" "$bash_config" 1> /dev/null && return 0

	# Continuar
	echo "Configurando o arquivo [$bash_config]"
	sed -i "/^export.*PATH.*:/d" ~/.bashrc
	echo "export PATH=$PATH" >> "$bash_config"
	echo "Execute ... bash -c \"source $bash_config\""
}

config_zshrc()
{
	# Criar o arquivo ~/.zshrc se não existir
	if [ ! -f "$zsh_config" ]; then
		echo ' ' >> "$zsh_config"
	fi

	# Se a linha de configuração já existir, encerrar a função aqui.
	grep "$HOME/.local/bin" "$zsh_config" 1> /dev/null && return 0

	# Continuar
	echo "Configurando o arquivo [$zsh_config]"
	echo "export PATH=$PATH" >> "$zsh_config"
}

backup()
{
	if [ -f "$bash_config" ]; then
		if [ ! -f ~/.bashrc.backup ]; then
			printf "\033[5;33mCriando backup do arquivo\033[m ..... ~/.bashrc => ~/.bashrc.backup\n"
			cp -v ~/.bashrc ~/.bashrc.backup
			sleep 1
		fi
	fi

	if [ -f "$zsh_config" ]; then
		if [ ! -f ~/.zshrc.backup ]; then
			printf "\033[5;33mCriando backup do arquivo\033[m ..... ~/.zshrc => ~/.zshrc.backup\n"
			cp -v ~/.zshrc ~/.zshrc.backup
			sleep 1
		fi
	fi
}

main()
{
	backup
	config_bashrc
	config_zshrc
}

main

