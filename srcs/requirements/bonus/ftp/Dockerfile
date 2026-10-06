# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:06:58 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:34:20 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends vsftpd openssl \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh \
	&& mkdir -p /var/run/vsftpd/empty /etc/ssl/vsftpd

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/init.sh"]