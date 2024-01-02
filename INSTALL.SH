NC_DB=nextcloud_db
NC_DB_USER=nextcloud_db_user
NC_DB_USER_PASS=nextcloud_db_user_pass

HOST_IP=$(hostname -I | head -n1 | cut -f1 -d' ')

apt install -y sudo wget unzip bzip2  lbzip2
sudo apt install -y apache2 openssl
sudo apt install -y php libapache2-mod-php php-mysql php-common php-gd php php-fpm php-curl php-cli php-xml php-json php-intl php-pear php-imagick php-dev php-common php-mbstring php-zip php-soap php-bz2 php-bcmath php-gmp php-apcu libmagickcore-dev php-redis php-memcached

sleep 2

PHP_VERSION=$(php -v | head -n1 | cut -d " " -f 2 | cut -d "." -f 1,2)
export DIR_APACHE=/etc/php/$PHP_VERSION/apache2/php.ini

cp $DIR_APACHE $DIR_APACHE.bkp

sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/g' $DIR_APACHE
sudo sed -i 's/max_execution_time = 30/max_execution_time = 3000/g' $DIR_APACHE
sudo sed -i 's/memory_limit = 128M/memory_limit = 4096M/g' $DIR_APACHE
sudo sed -i 's/post_max_size = 8M/post_max_size = 4096M/g' $DIR_APACHE
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1024000M/g' $DIR_APACHE
sudo sed -i 's/display_errors = On/display_errors = Off/g' $DIR_APACHE
sudo sed -i 's/output_buffering = 4096/output_buffering = Off/g' $DIR_APACHE
sudo sed -i 's/file_uploads = Off/file_uploads = On/g' $DIR_APACHE
sudo sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' $DIR_APACHE
sudo sed -i 's/;zend_extension/zend_extension/g' $DIR_APACHE
echo
sudo sed -i 's/;opcache.enable=1/opcache.enable=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=32/g' $DIR_APACHE
sudo sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/g' $DIR_APACHE
sudo sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=512/g' $DIR_APACHE
sudo sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/g' $DIR_APACHE
sudo sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=1/g' $DIR_APACHE
sudo sed -i 's/opcache.memory_consumption=128/opcache.memory_consumption=1024/g' $DIR_APACHE
sudo sed -i 's/opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=1024/g' $DIR_APACHE
echo

sudo sed -i 's|;clear_env|clear_env|g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
echo "apc.enable_cli = 1" >> /etc/php/$PHP_VERSION/cli/php.ini

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

cat >> /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/nextcloud/
    ServerName HOST_IP
    Redirect permanent / https://HOST_IP/
</VirtualHost>
EOF
mkdir /etc/ssl/certs/nextcloud
openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/nextcloud/key.pem -out /etc/ssl/certs/nextcloud/cert.pem -sha256 -days 3650 -nodes -subj "/C=BR/ST=Parana/L=Curitiba/O=nextcloud/OU=nextcloud/CN=localhost"

cat >> /etc/apache2/sites-available/nextcloud-ssl.conf << EOF
<VirtualHost *:443>
    DirectoryIndex index.html index.php
    ServerAdmin contact@mydomain.com
    DocumentRoot /var/www/html/nextcloud
    ServerName HOST_IP
    ErrorLog /var/log/nextcloud.log
    CustomLog /var/log/nextcloud-access.log combined
    SSLEngine on
    SSLProtocol all
        SSLCertificateFile /etc/ssl/certs/nextcloud/cert.pem
        SSLCertificateKeyFile /etc/ssl/certs/nextcloud/key.pem
        #SSLCertificateChainFile /etc/ssl/certs/nextcloud/ca.pem
    <IfModule mod_headers.c>
      Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </IfModule>
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
</VirtualHost>
EOF

sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/apache2/sites-available/nextcloud.conf
sudo sed -i "s/HOST_IP/$HOST_IP/g" /etc/apache2/sites-available/nextcloud-ssl.conf

sudo a2enmod ssl
sudo a2ensite nextcloud-ssl.conf
sudo systemctl restart apache2
apachectl configtest

sudo a2enmod setenvif headers rewrite env dir mime
sleep 2
sudo systemctl enable apache2
sleep 2
sudo systemctl restart apache2 --no-page -l
sleep 2
sudo systemctl reload apache2
sleep 2
sudo systemctl restart apache2

sleep 2

echo
echo "Instalação Concluída!"
echo
echo "Acesse via broswer https://$HOST_IP e configure:"
echo 
echo "Banco de dados: $NC_DB"
echo "Usuário: $NC_DB_USER"
echo "Senha: $NC_DB_USER_PASS"
echo
echo "Após concluir, execute o arquivo FIX.SH"
echo
