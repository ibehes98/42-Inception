# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 10:35:22 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 18:34:43 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

-include srcs/.env

COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

SECRETS =	db_root_password \
		 	db_user_password \
		 	ftp_password \
		 	stats_password \
		 	wp_admin_password \
		 	wp_user_password \

all: up

up: check dirs
	$(COMPOSE) up -d --build

check:
	@test -f srcs/.env || (echo "File .env not found"; exit 1)
	@for s in $(SECRETS); do \
		test -f secrets/$$s.txt || (echo "Secret $$s.txt not found"; exit 1); \
	done

dirs:
	mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress \
		$(DATA_PATH)/nginx_logs $(DATA_PATH)/goaccess_report

down:
	$(COMPOSE) down

clean: down
	$(COMPOSE) down --rmi all --remove-orphans

fclean: down
	$(COMPOSE) down --rmi all --volumes --remove-orphans
	docker run --rm -v $(DATA_PATH):/data debian:bookworm sh -c 'rm -rf /data/*'
	rm -rf $(DATA_PATH)

re: fclean all

logs:
	$(COMPOSE) logs -f

.PHONY: all up dirs down clean fclean re logs