exit_if_failed () {
  if [ $1 = 0 ]; then
    return 0;
  fi

  echo -e "\n\n\n  Desculpe, mas a instalação não pode continuar pois ocorreu algum erro inesperado."
  echo -e "\n  Por favor, tente novamente."

  exit 1;
}

echo -e '\n  * instalando dependências\n'

# fix "Failed to fetch bzip2 ... Hash Sum mismatch" error on apt-get update
sudo rm -rf /var/lib/apt/lists/*

apt-get update -y
apt-get install -y curl wget rpl unzip vim
exit_if_failed $?

sudo apt-get install -y libreadline6 libreadline6-dev make gcc zlib1g-dev flex bison
exit_if_failed $?

echo -e '\n\n  * instalando apache\n'
sudo apt-get install -y apache2
exit_if_failed $?

sudo a2enmod rewrite
exit_if_failed $?

sudo service apache2 restart
exit_if_failed $?

echo -e '\n\n  * instalando php\n'
sudo apt-get install -y libapache2-mod-php5 php5-pgsql php5-curl
exit_if_failed $?

echo -e '\n\n  * instalando pear\n'
sudo apt-get install -y php-pear
exit_if_failed $?

sudo service apache2 restart
exit_if_failed $?

echo -e '\n\n  * instalando git\n'
sudo apt-get install -y git-core
exit_if_failed $?

echo -e '\n\n  * instalando pgvm\n'
VAGRANT_HOME=/home/vagrant
curl -s -L https://raw.github.com/krlsdu/pgvm/master/bin/pgvm-self-install  | bash -s -- --pgvm-home=$VAGRANT_HOME/.pgvm

echo "source $VAGRANT_HOME/.pgvm/pgvm_env" >> $VAGRANT_HOME/.bashrc

source $VAGRANT_HOME/.pgvm/pgvm_env

echo -e '\n\n  * instalando postgres 8.2 via pgvm\n'

DBVERSION="$( pgvm list|grep -o 8.2.23)"

if [ -z "$DBVERSION" ] || [ "$DBVERSION" != "8.2.23" ]; then
  pgvm install 8.2
fi
pgvm use 8.2.23

chown vagrant:vagrant -R $VAGRANT_HOME/.pgvm
chmod 755 -R $VAGRANT_HOME/.pgvm

echo -e '\n\n  * instalando dependências i-Educar via pear\n'

wget -nv http://download.pear.php.net/package/Mail-1.2.0.tgz
wget -nv http://download.pear.php.net/package/Net_Socket-1.0.14.tgz
wget -nv http://download.pear.php.net/package/Net_SMTP-1.6.2.tgz
wget -nv http://download.pear.php.net/package/Net_URL2-2.0.5.tgz
wget -nv http://download.pear.php.net/package/HTTP_Request2-2.2.0.tgz
wget -nv http://download.pear.php.net/package/Services_ReCaptcha-1.0.3.tgz

sudo pear install -O Mail-1.2.0.tgz
exit_if_failed $?

sudo pear install -O Net_Socket-1.0.14.tgz
exit_if_failed $?

sudo pear install -O Net_SMTP-1.6.2.tgz
exit_if_failed $?

sudo pear install -O Net_URL2-2.0.5.tgz
exit_if_failed $?

sudo pear install -O HTTP_Request2-2.2.0.tgz
exit_if_failed $?

sudo pear install -O Services_ReCaptcha-1.0.3.tgz
exit_if_failed $?

rm Mail-1.2.0.tgz
rm Net_Socket-1.0.14.tgz
rm Net_SMTP-1.6.2.tgz
rm Net_URL2-2.0.5.tgz
rm HTTP_Request2-2.2.0.tgz
rm Services_ReCaptcha-1.0.3.tgz

sudo service apache2 restart

echo -e '\n\n  * instalando job crontab para inicializar o banco de dados ao iniciar o servidor\n'

crontab -l > tmp_crontab
echo "@reboot $VAGRANT_HOME/.pgvm/environments/8.2.23/bin/postgres -D $VAGRANT_HOME/.pgvm/clusters/8.2.23/main" >> tmp_crontab

crontab tmp_crontab
rm tmp_crontab

