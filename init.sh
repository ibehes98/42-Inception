# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    init.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 10:35:10 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 12:57:24 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# VM setup
sudo apt-get update \
&& apt-get install -y -qq --no-install-recommends \
    docker.io docker-compose make curl openssh-server

sudo usermod -aG docker $USER

echo "127.0.0.1 ibeltran.42.fr" | sudo tee -a /etc/hosts

# MariaDB test
docker exec -it mariadb mariadb -u wpuser -p
    SHOW DATABASES;
docker exec mariadb mariadb -u root

