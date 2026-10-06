#!/bin/bash

set -eu

WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
DB_USER_PASSWORD=$(cat /run/secrets/db_user_password)

echo "[wordpress] Waiting for MariaDB..."

for i in $(seq 1 30); do
	if mariadb-admin ping -h mariadb -u "$MYSQL_USER" --password="$DB_USER_PASSWORD" --silent 2>/dev/null; then
		echo "[wordpress] MariaDB available."
		break
	fi
	if [ "$i" -eq 30 ]; then
		echo "[wordpress] ERROR: MariaDB is not responding." >&2
		exit 1
	fi
	sleep 2
done

if [ ! -f wp-load.php ]; then
	echo "[wordpress] Downloading WordPress..."
	wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
	echo "[wordpress] Configuring  WordPress..."

	wp config create --allow-root \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$DB_USER_PASSWORD" \
		--dbhost="mariadb:3306"
fi

if ! wp core is-installed --allow-root 2>/dev/null; then
	echo "[wordpress] Installing WordPress..."
	wp core install --allow-root \
		--url="https://${DOMAIN_NAME}" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email

	wp user create --allow-root \
		"$WP_USER" "$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$WP_USER_PASSWORD"

	echo "[wordpress] Installation completed."

else
	echo "[wordpress] WordPress already installed."
fi

wp config set WP_REDIS_HOST redis --allow-root
wp config set WP_REDIS_PORT 6379 --raw --allow-root

if ! wp plugin is-installed redis-cache --allow-root; then
	wp plugin install redis-cache --activate --allow-root
fi

if [ ! -f wp-content/object-cache.php ]; then
	wp redis enable --allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F