# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:08:16 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:40:48 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends nginx \
	&& rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY conf/static.conf /etc/nginx/conf.d/static.conf
COPY site/ /var/www/static/

EXPOSE 8080

ENTRYPOINT ["nginx", "-g", "daemon off;"]