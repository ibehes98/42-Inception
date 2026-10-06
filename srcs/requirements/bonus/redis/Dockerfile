# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:07:25 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 17:47:50 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends redis-server \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/redis.conf /etc/redis/redis.conf

USER redis

EXPOSE 6379

ENTRYPOINT ["redis-server", "/etc/redis/redis.conf"]