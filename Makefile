# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 10:35:22 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:46:50 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

include srcs/.env

COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

all: up

up: dirs
	$(COMPOSE) up -d --build

dirs:
	mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress \
		$(DATA_PATH)/nginx_logs $(DATA_PATH)/goaccess_report

down:
	$(COMPOSE) down

clean: down
	docker system prune -af

fclean: down
	$(COMPOSE) down -v --rmi all
	rm -rf $(DATA_PATH)
	docker system prune -af

re: fclean all

logs:
	$(COMPOSE) logs -f

.PHONY: all up dirs down clean fclean re logs