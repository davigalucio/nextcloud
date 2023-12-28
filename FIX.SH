DIR_NC_CONFIG=/var/www/html/nextcloud/config/config.php

cp $DIR_NC_CONFIG $DIR_NC_CONFIG.bkp

sudo sed -i 's|);||g' $DIR_NC_CONFIG

cat >> $DIR_NC_CONFIG << EOL
  'default_phone_region' => 'BR',
  'memcache.local' => '\OC\Memcache\APCu',
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'memcache.distributed' => '\\OC\\Memcache\\Memcached',
  'redis' => 
     array (
       'host' => 'localhost',
       'port' => 0,
       'timeout' => 0.0,
     ),
  );
EOL
