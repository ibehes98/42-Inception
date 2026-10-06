# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    init.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:06:47 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:32:42 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash
set -eu

FTP_PASSWORD=$(cat /run/secrets/ftp_password)
SSL_DIR=/etc/ssl/vsftpd

if [ ! -f "$SSL_DIR/vsftpd.crt" ]; then
	openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
		-keyout	"$SSL_DIR/vsftpd.key" \
		-out	"$SSL_DIR/vsftpd.crt" \
		-subj	"/O=42/CN=${DOMAIN_NAME}" 2> /dev/null
	chmod 600 "$SSL_DIR/vsftpd.key"
	echo "[ftp] TLS certificate generated."
fi

if ! id "$FTP_USER" > /dev/null 2>&1; then
	useradd -o -K UID_MIN=1 -u 33 -g 33 -d /var/www/html -s /bin/bash "$FTP_USER"
	echo "[ftp] User $FTP_USER created."
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
echo "$FTP_USER" > /etc/vsftpd.userlist

touch /var/log/vsftpd.log

sed -i "s/^pasv_address=.*/pasv_address=${FTP_PASV_ADDRESS}/" /etc/vsftpd.conf

echo "[ftp] vsftpd is listening on port 21 (passive ${FTP_PASV_ADDRESS}:21100-21110)"

exec vsftpd /etc/vsftpd.conf