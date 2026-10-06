# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    init.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/06 12:07:10 by ibeltran          #+#    #+#              #
#    Updated: 2026/10/06 13:35:04 by ibeltran         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash
set -eu

LOG_FILE=/var/log/nginx/shared/access.log

touch "$LOG_FILE"

exec goaccess "$LOG_FILE" \
	--log-format=COMBINED \
	--real-time-html \
	--output=/var/www/goaccess/index.html \
	--addr=0.0.0.0 \
	--port 7890 \
	--ws-url="wss://${DOMAIN_NAME}:443/stats/ws" \
	--ignore-crawlers