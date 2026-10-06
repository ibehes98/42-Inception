# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:08:36 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 17:49:01 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y -qq --no-install-recommends mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh \
	&& mkdir -p /run/mysqld \
	&& chown mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]