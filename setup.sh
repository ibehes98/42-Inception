#!/bin/bash

# VM setup
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    docker.io docker-compose make curl lftp openssh-server

sudo usermod -aG docker $USER
sudo systemctl enable --now ssh

echo "127.0.0.1 ibeltran.42.fr" | sudo tee -a /etc/hosts

# MariaDB test
docker exec -it mariadb mariadb -u wpuser -p
    SHOW DATABASES;
    exit
docker exec mariadb mariadb -u root # should fail

# WordPress test
docker ps
docker exec wordpress wp user list --allow-root
ls /home/ibeltran/data/wordpress

# Nginx test
docker ps
curl -vk https://ibeltran.42.fr 2>&1 | grep -E "SSL connection|HTTP/"
openssl s_client -connect ibeltran.42.fr:443 -tls1_2 < /dev/null
openssl s_client -connect ibeltran.42.fr:443 -tls1_1 < /dev/null # should fail
curl -v http://ibeltran.42.fr # should fail

# Redis test
docker exec redis redis-cli ping
docker exec wordpress wp redis status --allow-root
docker exec redis redis-cli dbsize

# Static test
curl -k https://ibeltran.42.fr/static/
curl -kI https://ibeltran.42.fr/static # should return 301

# Adminer test
curl -kI https://ibeltran.42.fr/adminer/ # wpuser credentials

# FTP test
echo "Hello from FTP" > test.txt
echo "Hello from FTP" > test.php
lftp -u ibeltran_ftp -e "set ftp:ssl-allow no; ls; bye" ftp://127.0.0.1 # should return 530
lftp -u ibeltran_ftp -e "set ftp:ssl-force true; set ssl:verify-certificate no" ftp://127.0.0.1
    ls
    put test.txt
    put test.php # should fail
    mv test.txt test.php # should fail
    cd /
    bye
docker exec wordpress ls -l /var/www/html/test.txt
docker exec wordpress rm -f /var/www/html/test.txt /var/www/html/test.php
curl -k https://ibeltran.42.fr/test.txt
openssl s_client -connect 127.0.0.1:21 -starttls ftp -tls1_2 < /dev/null
openssl s_client -connect 127.0.0.1:21 -starttls ftp -tls1_1 < /dev/null # should fail
docker exec ftp tail -n 30 /var/log/vsftpd.log

docker exec wordpress sh -c 'mkdir-p /var/www/html/wp-content/uploads && echo "<?php echo 1;" > /var/www/html/wp-content/uploads/test.php'
curl -k -o /dev/null -w "%{http_code}\n" https://ibeltran.42.fr/wp-content/uploads/test.php # should return 403
docker exec wordpress rm /var/www/html/wp-content/uploads/test.php


# Goaccess test
# abrir https://ibeltran.42.fr/stats/ en el navegador
for i in $(seq 1 30); do
    curl -sk -o /dev/null https://ibeltran.42.fr/
    curl -sk -o /dev/null https://ibeltran.42.fr/static/
    curl -sk -o /dev/null https://ibeltran.42.fr/no-existe
    sleep 0.5
done

curl -k -o /dev/null -w "%{http_code}\n" https://ibeltran.42.fr/stats/ # should return 401
curl -k -o /dev/null -w "%{http_code}\n" https://ibeltran.42.fr/stats/ws # should return 401
curl -k -o /dev/null -w "%{http_code}\n" -u ibeltran_stats:mala https://ibeltran.42.fr/stats/ # should return 401
curl -k -o /dev/null -w "%{http_code}\n" -u ibeltran_stats:stats_secure https://ibeltran.42.fr/stats/

docker exec nginx cat /etc/nginx/.htpass