# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:06:21 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 17:48:32 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

ARG ADMINER_VERSION=5.5.1

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends \
		php8.2-fpm php8.2-mysql curl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer /run/php \
	&& curl -fsSL -o /var/www/adminer/index.php \
		"https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php"

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE 9000

ENTRYPOINT ["php-fpm8.2", "-F"]