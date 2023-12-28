NC_DB=nextcloud_db
NC_DB_USER=nextcloud_db_user
NC_DB_USER_PASS=nextcloud_db_user_pass

HOST_IP=$(hostname -I | head -n1 | cut -f1 -d' ')

apt install -y sudo wget unzip bzip2  lbzip2
sudo apt install -y apache2
sudo apt install -y php redis-server libapache2-mod-php php-mysql php-common php-gd php php-fpm php-curl php-cli php-xml php-json php-intl php-pear php-imagick php-dev php-common php-mbstring php-zip php-soap php-bz2 php-bcmath php-gmp php-apcu libmagickcore-dev php-redis php-memcached

sleep 2

PHP_VERSION=$(php -v | head -n1 | cut -d " " -f 2 | cut -d "." -f 1,2)
export DIR_APACHE=/etc/php/$PHP_VERSION/apache2/php.ini

cp $DIR_APACHE $DIR_APACHE.bkp

sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/g' $DIR_APACHE
sudo sed -i 's/max_execution_time = 30/max_execution_time = 3000/g' $DIR_APACHE
sudo sed -i 's/memory_limit = 128M/memory_limit = 10G/g' $DIR_APACHE
sudo sed -i 's/post_max_size = 8M/post_max_size = 10G/g' $DIR_APACHE
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100G/g' $DIR_APACHE
sudo sed -i 's/display_errors = On/display_errors = Off/g' $DIR_APACHE
sudo sed -i 's/output_buffering = 4096/output_buffering = Off/g' $DIR_APACHE
sudo sed -i 's/file_uploads = Off/file_uploads = On/g' $DIR_APACHE
sudo sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' $DIR_APACHE
sudo sed -i 's/;zend_extension/zend_extension/g' $DIR_APACHE
echo
sudo sed -i 's/;opcache.enable=1/opcache.enable=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/g' $DIR_APACHE
sudo sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/g' $DIR_APACHE
sudo sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=128/g' $DIR_APACHE
sudo sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=1/g' $DIR_APACHE
sudo sed -i 's/opcache.memory_consumption=128/opcache.memory_consumption=1024/g' $DIR_APACHE
sudo sed -i 's/opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=512/g' $DIR_APACHE
echo
cat $DIR_APACHE | grep "date.timezone =" | head -n1
cat $DIR_APACHE | grep "max_execution_time =" | head -n1
cat $DIR_APACHE | grep "memory_limit =" | head -n1
cat $DIR_APACHE | grep "post_max_size =" | head -n1
cat $DIR_APACHE | grep "upload_max_filesize =" | head -n1
cat $DIR_APACHE | grep "display_errors =" | head -n1
cat $DIR_APACHE | grep "output_buffering =" | head -n1
cat $DIR_APACHE | grep "file_uploads =" | head -n1
cat $DIR_APACHE | grep "allow_url_fopen =" | head -n1
cat $DIR_APACHE | grep "zend_extension =" | head -n1
echo
cat $DIR_APACHE | grep opcache.enable= | head -n1
cat $DIR_APACHE | grep opcache.interned_strings_buffer= | head -n1
cat $DIR_APACHE | grep opcache.max_accelerated_files= | head -n1
cat $DIR_APACHE | grep opcache.memory_consumption= | head -n1
cat $DIR_APACHE | grep opcache.save_comments= | head -n1
cat $DIR_APACHE | grep opcache.revalidate_freq= | head -n1
cat $DIR_APACHE | grep opcache.memory_consumption= | head -n1
cat $DIR_APACHE | grep opcache.interned_strings_buffer= | head -n1

sleep 2

cat >> /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/nextcloud/
    ServerName HOST_IP

    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/apache2/sites-available/nextcloud.conf

sudo ln -s /etc/apache2/sites-available/nextcloud.conf /etc/apache2/sites-enabled/
sudo a2enmod headers rewrite env dir mime
sudo systemctl restart apache2 --no-page -l
sudo service apache2 reload
sudo service apache2 restart

cp /etc/redis/redis.conf /etc/redis/redis.conf.bkp
sudo sed -i "s|port 6379|port 0|g" /etc/redis/redis.conf
sudo sed -i "s|# unixsocket /|unixsocket /|g" /etc/redis/redis.conf
sudo sed -i "s|# unixsocketperm 700|unixsocketperm 770|g" /etc/redis/redis.conf
sudo usermod -a -G redis www-data
sudo service redis-server start
sudo systemctl enable redis-server
sudo service redis-server restart

sudo apt install -y mariadb-server

cat >> /opt/nextcloud_config.sql << EOL
CREATE DATABASE $NC_DB;
CREATE USER $NC_DB_USER@localhost IDENTIFIED BY '$NC_DB_USER_PASS';
GRANT ALL PRIVILEGES ON $NC_DB.* TO $NC_DB_USER@localhost;
FLUSH PRIVILEGES;
EOL

mysql -u root < /opt/nextcloud_config.sql

wget -P /opt/ https://download.nextcloud.com/server/releases/latest.tar.bz2
tar xvf /opt/latest.tar.bz2 -C /var/www/html/
sudo mkdir -p /var/www/html/nextcloud/data
sudo chown -R www-data:www-data /var/www/html/nextcloud/
sudo chmod -R 755 /var/www/html/nextcloud/

sleep 2

echo
echo "Instalação Concluída!"
echo
echo "Acesse via broswer http://$HOST_IP e configure:"
echo 
echo "Banco de dados: $NC_DB"
echo "Usuário: $NC_DB_USER"
echo "Senha: $NC_DB_USER_PASS"
echo
echo "Após concluir, execute o arquivo FIX.SH"
echo
