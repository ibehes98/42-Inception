# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    init.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:08:43 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:04:10 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash
set -eu

SSL_DIR=/etc/nginx/ssl

if [ ! -f "$SSL_DIR/inception.crt" ]; then
	echo "[nginx] Generating self signed certificate for ${DOMAIN_NAME}..."
	openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
		-keyout	"$SSL_DIR/inception.key" \
		-out	"$SSL_DIR/inception.crt" \
		-subj	"/O=42/CN=${DOMAIN_NAME}"
fi

openssl passwd -6 -stdin < /run/secrets/stats_password \
	| sed "s/^/${STATS_USER}:/" > /etc/nginx/.htpasswd

chown root:www-data /etc/nginx/.htpasswd
chmod 640 /etc/nginx/.htpasswd

envsubst '${DOMAIN_NAME}' \
	< /etc/nginx/templates/inception.conf.template \
	> /etc/nginx/conf.d/inception.conf

nginx -t

exec nginx -g 'daemon off;'