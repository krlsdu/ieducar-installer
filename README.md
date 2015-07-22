# Instalador do iEducar
Este projeto permite provisionar máquina e instalar o software de gestão escolar iEducar em máquina virtual utilizando a ferramenta vagrant.

O instalador permite customizar no momento da instalação:  

* O nome do banco de dados.
* O nome do usuário do banco
* O nome do diretório de instalação.

## Dependências

* Vagrant
* Virtual Box
* Acesso a internet

## Como instalar

### Clone o repositório
 
 ```
 git clone https://github.com/krlsdu/ieducar-installer.git
 ```
 
### Crie a máquina virtual
 
 ```
 vagrant up
 ```
 
### Acesse a máquina virtual
 
 ```
 vagrant ssh
 ```
 
## Configure o ambiente
 
#### Configurações padrão
  
  ```
 curl https://raw.githubusercontent.com/krlsdu/ieducar-installer/master/installer.sh | bash
 ```
 
#### Configuração personalizada
 
 ```
 curl https://raw.githubusercontent.com/krlsdu/ieducar-installer/master/installer.sh | bash -s -- DBNAME=ieducar DBUSER=ieducar APPDIR=ieducar
 ```

## Licença

# Sobre este fork

É uma compilação do trabalho de Lucas D'Avila. e da Comunidade ieducativa
