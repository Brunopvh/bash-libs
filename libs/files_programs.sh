#!/usr/bin/env bash
#
version_files_programs='2021-02-16'
#
# Este módulo/lib guarda o caminho de arquivos e diretórios de instalação de alguns pacotes.
# Exemplos:
#    Caminho de arquivos '.desktop', .png, diretórios e binários de programas intalados via
# pacote tar.gz, zip e outros.
#=============================================================#
#
# - REQUERIMENT = os
#

[[ -z $PATH_BASH_LIBS ]] && source ~/.shmrc
[[ ! -f $os ]] && {
	echo "(files_programs) ERRO: módulo os.sh não encontrado."
	sleep 1
	exit 1
}

source $os
export lib_files_programs='True'

# Verificar se as variáveis com os diretórios de configuração e instalação dos
# aplicativos foram definidas.
[[ ! -d $DIR_BIN ]] && mkdir "$DIR_BIN"
[[ ! -d $DIR_APPLICATIONS ]] && mkdir "$DIR_APPLICATIONS"
[[ ! -d $DIR_ICONS ]] && mkdir "$DIR_ICONS"
[[ ! -d $DIR_THEMES ]] && mkdir "$DIR_THEMES"
[[ ! -d $DIR_APPLICATIONS ]] && mkdir "$DIR_APPLICATIONS"
[[ ! -d $DIR_LIB ]] && mkdir "$DIR_LIB"
[[ ! -d $DIR_SHARE ]] && mkdir "$DIR_SHARE"
[[ ! -d $DIR_OPTIONAL ]] && mkdir "$DIR_OPTIONAL"
[[ ! -d $DIR_HICOLOR ]] && mkdir "$DIR_HICOLOR"


#=============================================================#
# Acessorios
#=============================================================#
# Etcher
declare -A destinationFilesEtcher
destinationFilesEtcher=(
	[file_desktop]="$DIR_APPLICATIONS/balena-etcher-electron.desktop"
	[file_appimage]="$DIR_BIN/balena-etcher-electron"
	)

declare -A destinationFilesStorecli
destinationFilesStorecli=(
	[file_desktop]="$DIR_APPLICATIONS/storecli.desktop"
	[link]="$DIR_BIN/storecli"
	[dir]="$DIR_BIN/storecli-amd64"
	)

#=============================================================#
# Desenvolvimento
#=============================================================#
# Android Studio
declare -A destinationFilesAndroidStudio
destinationFilesAndroidStudio=(
	[file_desktop]="$DIR_APPLICATIONS/jetbrains-studio.desktop"
	[file_png]="$DIR_ICONS/studio.png"
	[link]="$DIR_BIN/studio"
	[dir]="$DIR_BIN/android-studio"
	)

declare -A destinationFilesIdeaic
destinationFilesIdeaic=(
	[file_desktop]="$DIR_APPLICATIONS/jetbrains-idea.desktop"
	[file_png]="$DIR_ICONS/idea.png"
	[file_script]="$DIR_BIN/idea"
	[dir]="$DIR_BIN/idea-IC"
	)


declare -A destinationFilesNodejs
destinationFilesNodejs=(             
	[script]="$DIR_BIN/nodejs"                  
	[dir]="$DIR_BIN/nodejs-amd64"
	[npm_link]="$DIR_BIN/npm" 
	[npx_link]="$DIR_BIN/npx"           
)

declare -A destinationFilesPycharm
destinationFilesPycharm=(
	[file_desktop]="$DIR_APPLICATIONS/pycharm.desktop"
	[file_png]="$DIR_ICONS/pycharm.png"
	[link]="$DIR_BIN/pycharm"
	[dir]="$DIR_BIN/pycharm-community"
	)

declare -A destinationFilesSublime
destinationFilesSublime=(
	[file_desktop]="$DIR_APPLICATIONS/sublime_text.desktop"
	[file_png]="$DIR_ICONS/sublime-text.png"
	[link]="$DIR_BIN/sublime"
	[dir]="/opt/sublime_text"
	)

declare -A destinationFilesVscode
destinationFilesVscode=(
	[file_desktop]="$DIR_APPLICATIONS/code.desktop"  
	[file_png]="$DIR_ICONS/code.png"             
	[link]="$DIR_BIN/code"                  
	[dir]="$DIR_BIN/code-amd64"            
)

#=============================================================#
# Escritorio
#=============================================================#

# Libreoffice AppImage.
declare -A destinationFilesLibreofficeAppimage
destinationFilesLibreofficeAppimage=(
	[file_desktop]="$DIR_APPLICATIONS/libreoffice-appimage.desktop"   
	[file_appimage]="$DIR_BIN/libreoffice-appimage"                            
)

#=============================================================#
# Midia
#=============================================================#


#=============================================================#
# Navegadores
#=============================================================#

#=============================================================#
# Internet
#=============================================================#

declare -A destinationFilesTelegram
destinationFilesTelegram=(
	[file_desktop]="$DIR_APPLICATIONS/telegramdesktop.desktop" 
	[file_png]="$DIR_ICONS/telegram.png"                  
	[link]="$DIR_BIN/telegram"                       
	[dir]="$DIR_OPTIONAL/telegram-amd64"                  
)


declare -A destinationFilesTixati
destinationFilesTixati=(
	[file_desktop]="$DIR_APPLICATIONS/tixati.desktop"
	[file_png]="$DIR_ICONS/tixati.png" 
	[file_bin]="$DIR_BIN/tixati"                                       
)


destinationFilesTeamviewer=(
	'/opt/teamviewer'
	'/usr/bin/teamviewer'
	"/usr/share/icons/hicolor/16x16/apps/TeamViewer.png"
	"/usr/share/icons/hicolor/20x20/apps/TeamViewer.png"
	"/usr/share/icons/hicolor/24x24/apps/TeamViewer.png"
	"/usr/share/icons/hicolor/32x32/apps/TeamViewer.png"
	"/usr/share/icons/hicolor/48x48/apps/TeamViewer.png"
	"/usr/share/icons/hicolor/256x256/apps/TeamViewer.png"
	"$DIR_APPLICATIONS/com.teamviewer.TeamViewer.desktop"
	'/usr/share/dbus-1/services/com.teamviewer.TeamViewer.Desktop.service'
	'/usr/share/dbus-1/services/com.teamviewer.TeamViewer.service'
	'/usr/share/polkit-1/actions/com.teamviewer.TeamViewer.policy'
	'/etc/systemd/system/multi-user.target.wants/teamviewerd.service'
)

declare -A destinationFilesYoutubeDlGuiUser
destinationFilesYoutubeDlGuiUser=(
	[file_desktop]="$DIR_APPLICATIONS/youtube-dl-gui.desktop"
	[file_png]="$DIR_ICONS/youtube-dl-gui.png" 
	[pixmaps]="$DIR_HICOLOR/youtube-dl-gui"
	[file_script]="$DIR_BIN/youtube-dl-gui"  
	[dir]="$DIR_BIN/youtube_dl_gui"                                     
)

#=============================================================#
# Sistema
#=============================================================#
# archlinux-installer
declare -A destinationFilesArchlinuxInstaller
destinationFilesArchlinuxInstaller=(
	[script]="$DIR_BIN/archlinux-installer"
	)

# Cpu-X
declare -A destinationFilesCpux
destinationFilesCpux=(
	[file_desktop]="$DIR_APPLICATIONS/cpux.desktop"  
	[file]="$DIR_BIN/cpux"                        
)


# PeaZip
declare -A destinationFilesPeazip
destinationFilesPeazip=(
	[file_desktop]="$DIR_APPLICATIONS/peazip.desktop" 
	[file_png]="$DIR_ICONS/peazip.png"
	[script]="$DIR_BIN/peazip"
	[dir]="/opt/peazip-amd64"
)


# Refind
declare -A destinationFilesRefind
destinationFilesRefind=(  
	[file_script]="$DIR_BIN/refind-install"
	[dir]="/opt/refind"
)

declare -A destinationFilesStacer
destinationFilesStacer=( 
	[file_desktop]="$DIR_APPLICATIONS/stacer.desktop"  
	[file_appimage]="$DIR_BIN/stacer"                            
)


#=============================================================#
# Preferências
#=============================================================#

# Papirus
declare -A destinationFilesPapirus
destinationFilesPapirus=(
	[papirus_dark]="$DIR_HICOLOR/Papirus-Dark" 
	[papirus_light]="$DIR_HICOLOR/Papirus-Light" 
	[epapirus]="$DIR_HICOLOR/ePapirus"
	[papirus]="$DIR_HICOLOR/Papirus" 
)

declare -A destinationFilesEpsxe
destinationFilesEpsxe=(
	[file_desktop]="$DIR_APPLICATIONS/epsxe.desktop"
	[file_png]="$DIR_ICONS/ePSxe.svg"
	[link]="$DIR_BIN/epsxe"
	[dir]="$DIR_BIN/epsxe-amd64"
)

declare -A destinationFilesEpsxeWin32
destinationFilesEpsxeWin32=(
	[file_desktop]="$DIR_APPLICATIONS/epsxe-win.desktop"
	[file_script]="$DIR_BIN/epsxe-win"
	[dir]="$HOME/.wine/drive_c/epsxe-win"
	)
