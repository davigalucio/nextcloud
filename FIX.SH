DIR_NC_CONFIG=/var/www/html/nextcloud/config/config.php

cp $DIR_NC_CONFIG $DIR_NC_CONFIG.bkp

sudo sed -i 's|);||g' $DIR_NC_CONFIG

cat >> $DIR_NC_CONFIG << EOL
  'default_phone_region' => 'BR',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Memcached',
  'memcache.locking' => '\\OC\\Memcache\\Memcached',
  'filelocking.enabled' => false,
  );
EOL

#sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
sudo -u www-data php --define apc.enable_cli=1 /var/www/html/nextcloud/occ maintenance:repair
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set maintenance_window_start --type=integer --value=1
