#!/usr/bin/env bash

set -e

service redis-server start;
php artisan optimize;
php artisan key:generate;
php artisan migrate:fresh --seed;
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
#echo 'starting up queue';
#php artisan queue:work --tries=3;
#echo 'starting up horizon';
#php artisan horizon;
#echo 'starting up schedule';
#php artisan schedule:run  --verbose;
#echo 'serving the app';
#php artisan serve --host=0.0.0.0 --port=8000;
