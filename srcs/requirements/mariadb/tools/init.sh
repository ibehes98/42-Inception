#!/bin/bash

set -eu

DB_USER_PASSWORD=$(cat /run/secrets/db_user_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

chown -R mysql:mysql /var/lib/mysql

if [ ! -f /var/lib/mysql/.inception_initialized ]; then
	echo "[mariadb] Initializing database..."

	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
EOF

	touch /var/lib/mysql/.inception_initialized
	echo "[mariadb] Initialization completed."

else
	echo "[mariadb] Existing data detected, skipping initialization."
fi

exec mysqld --user=mysql