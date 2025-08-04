echo "-Create admin-"
cd var/
wp config create --allow-root \
                 --dbname=$DB_NAME \
                 --dbuser=$DB_USER \
                 --dbpass=$DB_PASSWORD \
                 --dbhost=mariadb:3306 \
                 --path='/var/www/wordpress'

echo "-install Wordpress-"
if [ ! "$WP_CONNECTED_TO_DOMAIN_NAME" = "true" ]; then
	WP_URL="http://$(curl -s https://checkip.amazonaws.com)"
fi
wp core install --allow-root \
                --url=$WP_URL \
                --title=cloud-1 \
                --admin_user=$WP_ADMIN_USER \
                --admin_password=$WP_ADMIN_PASSWORD \
                --admin_email=info@example.com \
                --path='/var/www/wordpress' \

echo "-Update Homepage-"
CUSTOM_CONTENT="Hello world from $WP_URL !"
wp post update 1 \
    --post_title="Welcome to Cloud-1" \
    --post_content="$CUSTOM_CONTENT" \
    --allow-root \
    --path='/var/www/wordpress'

unset WP_ADMIN_PASSWORD

if [ ! -d /run/php ]; then
    mkdir ./run/php
fi

/usr/sbin/php-fpm7.4 -F