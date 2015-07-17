#!/usr/bin/env bash

<<LICENSE
Copyright (c) 2014 Lucas D'Avila.

--

This file is part of ieducar-installer.

Ieducar-installer is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, version 3 of the License.

Ieducar-installer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ieducar-installer.  If not, see <http://www.gnu.org/licenses/>.
LICENSE

echo -e '\n\n  Bem vindo a instalação do i-Educar.'
echo -e '\n  Este script lhe guiará na instalação do software, para mais detalhes acesse o site http://comunidade.ieducativa.com.br/'

exit_if_failed () {
  if [ $1 = 0 ]; then
    return 0;
  fi

  echo -e "\n\n\n  Desculpe, mas a instalação não pode continuar pois ocorreu algum erro inesperado."
  echo -e "\n  Por favor, tente novamente."

  exit 1;
}

required_read () {

  read -p "$1" _INPUT

  if [  -z "$_INPUT" ]; then
    required_read "$1"
  fi
}

login_or_create_user () {
  echo -e "\n  A instalação não pode ser realizada pelo usuário root, selecione uma opção:\n"
  echo -e '    1 - logar-se com outro usuário'
  echo -e '    2 - criar um novo usuário\n'

  required_read '    opção: '

  if [ $_INPUT = 1 ]; then
    echo -e '\n'
    required_read '    informe o nome do seu usuário: '

    su $_INPUT $0
    exit 0

  elif [[ $_INPUT = 2 ]]; then
    echo -e '\n'
    required_read '    informe o nome do novo usuário (ex: ieducar): '

    useradd --create-home --groups sudo --shell /bin/bash $_INPUT
    exit_if_failed $?

    echo -e '\n    por favor, informe a senha do novo usuário:\n'
    sudo passwd $_INPUT
    exit_if_failed $?

    su $_INPUT $0
    exit 0
  else
    echo -e '\n'
    echo -n '    opção inválida, tente novamente.'
    read -n 1

    login_or_create_user
  fi
}


configurar_banco() {

  echo -e '\n'
  required_read '    informe o nome desejado para o banco de dados (ex: ieducar): '
  DBNAME=$_INPUT

  echo -e '\n\n  * destruindo banco de dados caso exista\n'
  ~/.pgvm/environments/8.2.23/bin/dropdb $DBNAME -p 5433

  required_read '    informe o nome desejado para o usuario (ex: ieducar): '
  DBUSER=$_INPUT

  if [ $USER != $DBUSER ]; then
    echo -e '\n\n  * criando usuário do banco de dados\n'
    ~/.pgvm/environments/8.2.23/bin/psql -d postgres -p 5433 -c "DROP USER IF EXISTS $DBUSER;"
    ~/.pgvm/environments/8.2.23/bin/createuser --superuser $DBUSER -p 5433
    exit_if_failed $?
  fi

  echo -e '\n\n  * baixando dump banco de dados\n'
  rm -f /tmp/bootstrap.backup.zip
  rm -f /tmp/bootstrap.backup

  cp /vagrant/bootstrap.backup.zip /tmp
  unzip -q /tmp/bootstrap.backup.zip -d /tmp
  exit_if_failed $?

  echo -e '\n\n * restaurando dump do banco de dados\n'
  ~/.pgvm/environments/8.2.23/bin/createdb $DBNAME -E latin1 -p 5433
  exit_if_failed $?

  ~/.pgvm/environments/8.2.23/bin/pg_restore -d $DBNAME -p 5433 -U $DBUSER --no-owner /tmp/bootstrap.backup
  exit_if_failed $?

  rm -f /tmp/bootstrap.backup.zip
  rm -f /tmp/bootstrap.backup

  echo -e '\n\n * definindo search_path\n'
  ~/.pgvm/environments/8.2.23/bin/psql -d $DBNAME -p 5433 -c 'ALTER DATABASE '$DBNAME' SET search_path = "$user", public, portal, cadastro, acesso, alimentos, consistenciacao, historico, pmiacoes, pmicontrolesis, pmidrh, pmieducar, pmiotopic, urbano, modules;'
  exit_if_failed $?
}


clone_ieducar () {
  echo -e '\n'
  required_read '    informe o nome do diretório em que a aplicação será instalada (ex: ieducar): '
  APPDIR=$_INPUT

  echo -e '\n\n  * destruindo repositório ieducar local caso exista\n'
  rm -rf $HOME/$APPDIR

  echo -e "\n\n  * clonando repositório ieducar no caminho $HOME/$APPDIR\n"
  git clone https://github.com/ieducativa/ieducar.git -b ieducativa $HOME/$APPDIR
  exit_if_failed $?

  echo -e "\n\n  * reconfigurando ieducar\n"
  rpl "app.database.dbname   = ieducar" "app.database.dbname   = $DBNAME" $HOME/$APPDIR/ieducar/configuration/ieducar.ini
  rpl "app.database.username = ieducar" "app.database.username  = $DBUSER" $HOME/$APPDIR/ieducar/configuration/ieducar.ini
  sudo service apache2 reload
}



config_apache () {
  echo -e '\n\n  * configurando virtual host apache\n'
  sudo rm -f /etc/apache2/sites-enabled/ieducar
  sudo rm -f /etc/apache2/sites-available/ieducar
  sudo rm -f /etc/apache2/sites-available/apache-sites-available-ieducar

  sudo cp apache-sites-available-ieducar -P /etc/apache2/sites-available
  sudo mv /etc/apache2/sites-available/apache-sites-available-ieducar /etc/apache2/sites-available/ieducar

  echo -e "\n\n  * reconfigurando virtual host\n"
  sudo rpl "/home/lucasdavila/ieducar" "$HOME/$APPDIR" /etc/apache2/sites-available/ieducar
  sudo service apache2 reload

  sudo a2dissite 000-default
  sudo a2ensite ieducar
  sudo service apache2 restart

  if [ $ISSERVER = 0 ]; then
    echo -e '\n'
    required_read '    informe o host desejado para acesso local ao sistema no navegador (ex: ieducar.local): '
    HOST=$_INPUT

    if ! grep -q $HOST /etc/hosts; then
      echo -e '\n\n * adicionando host para $HOST\n'
      echo "127.0.0.1   $HOST" | sudo tee -a /etc/hosts
    fi
  fi
}



before_install () {
  dpkg -l ubuntu-desktop >/dev/null 2>/dev/null
  ISSERVER=$? # ! desktop
}

install () {

  before_install
  configurar_banco
  clone_ieducar
  config_apache

  echo -e '\n\n  --------------------------------------------'
  echo -e "\n  Parabéns o i-Educar foi instalado com sucesso,"

  server_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

  if [ $ISSERVER = 0 ]; then
    echo -e "  você pode acessar o sistema em http://$HOST/ (neste computador) ou em http://$server_ip/ nos demais computadores da rede local."
  else
    echo -e "  você pode acessar o sistema em http://$server_ip/"
  fi

  echo -e "\n  utilize usuário admin e senha admin"

  echo -e "\n\n  * Receba por email as novidades e atualizações do iEducar, assinando nossa lista de emails em http://goo.gl/gFXSia"

  echo -e '\n  --'
  echo -e "  Lucas D'Avila"
  echo -e '  lucas@ieducativa.com.br\n'
}

if [ $USER = 'root' ]; then
  login_or_create_user
else
  echo -e "\n\n  instalando i-Educar com usuário $USER"
  install
fi
