# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:08:46 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 17:54:47 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends nginx openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default \
	&& mkdir -p /etc/nginx/ssl /var/log/nginx/shared \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY conf/inception.conf /etc/nginx/conf.d/inception.conf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init.sh"]