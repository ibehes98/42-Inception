# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:07:15 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:35:21 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends goaccess \
	&& rm -rf /var/lib/apt/lists/*

COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh \
	&& mkdir -p /var/www/goaccess /var/log/nginx/shared

EXPOSE 7890

ENTRYPOINT ["/usr/local/bin/init.sh"]