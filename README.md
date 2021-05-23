# bash-libs
BashLibs

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Shell Package Manager - shm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Este repositório contém módulos para bash e um gerenciador de pacotes para instalar e remover estes módulos no seu sistema.

--------------------------------------------------
 INSTALAÇÃO
--------------------------------------------------
Use a ferramenta curl ou wget para executar o script que instala o gerenciador de pacotes no seu sistema.
Observação: Você também pode instalar o script na sua HOME usando o mesmo comando abaixo sem o 'sudo' ou 'root'.

 sudo sh -c "$(curl -fsSL https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 
 
 OU
 
 sudo sh -c "$(wget -q -O- https://raw.github.com/Brunopvh/bash-libs/main/setup.sh)" 

--------------------------------------------------
 USO
--------------------------------------------------
 Depois de executar o script de instalação configure o 
 programa para primeiro uso.
   Verifique se a instalação foi efetuada correntamente
   
   $ command -v shm -> se este comando não retornar o caminho do executável voĉe deve executar o seguinte comando
   $ ~/.local/bin/shm --configure -> Em seguida reinicie o shell/terminal ou encerre a sessão e faça login novamente
   para que o arquivo ~/.bashrc seja carregado.
   
   Verifique novamente a saída do comando:
   $ command -v shm
  
   
Destino da instalação para o root /usr/local/bin/shm
Destino para instalação na HOME: ~/.local/bin/shm 

 PRONTO agora você pode usar o script para instalar os módulos disponíveis no
 github. 
 
 $ shm --install <módulo> 
 
 OU
 
 $ sudo shm --install <módulo>

 $ shm --list => Exibe os módulos disponíveis
 $ shm --help => Mostra ajuda
 $ shm update => Atualiza a lista de modulos.
 $ shm --install <módulo> Exemplo shm --install requests os print_text
                          Instala os módulos os, print_text e requests.

 $ shm --self-update => Atualiza este script para ultima versão disponível no github.
 
