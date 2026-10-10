# Developer documentation

This guide explains how to set up the project from scratch, how it is built and launched, how to manage the containers and volumes, and where the data is stored.

## Set up the environment from scratch

### Prerequisites

- A Debian or Ubuntu virtual machine (tested on Debian 13).
- Docker Engine and the **Compose v2** plugin. Check with `docker compose version`: it must be 2.x. The old `docker-compose` 1.x is not supported.
- `make`, `git` and `openssl`.
- The user in the `docker` group: `sudo usermod -aG docker $USER`, then log out and back in (or run `newgrp docker`).
- Port 443 and 21 free on the VM (no NGINX or Apache installed on the host).

`setup.sh` installs the packages, enables SSH and adds the domain to `/etc/hosts`.

### Repository layout

```
.
├── Makefile
├── setup.sh                     # VM preparation and manual test commands
├── secrets/                     # passwords (not in git)
└── srcs/
    ├── .env                     # configuration (not in git)
    ├── .env.example             # template for .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   wordpress/   nginx/
        └── bonus/
            ├── redis/  ftp/  static/  adminer/  goaccess/
```

Each service directory contains a `Dockerfile`, a `conf/` directory with its configuration files and, when needed, a `tools/init.sh` entrypoint script.

### Configuration files

**`srcs/.env`** — copy it from `srcs/.env.example`:

| Variable | Meaning |
|---|---|
| `LOGIN` | 42 login |
| `DATA_PATH` | Host directory for persistent data (`/home/<login>/data`) |
| `DOMAIN_NAME` | `<login>.42.fr` |
| `MYSQL_DATABASE`, `MYSQL_USER` | WordPress database and its user |
| `WP_TITLE` | Site title |
| `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` | WordPress administrator (must not contain `admin`) |
| `WP_USER`, `WP_USER_EMAIL` | Second WordPress user (role: author) |
| `FTP_USER` | FTP account |
| `FTP_PASV_ADDRESS` | IP announced by the FTP server for passive mode |
| `STATS_USER` | HTTP basic auth user for `/stats/` and `/adminer/` |

**`secrets/`** — one password per file, without trailing newline (`printf`, not `echo`):

```bash
mkdir -p secrets
for s in db_root_password db_user_password wp_admin_password \
         wp_user_password ftp_password stats_password; do
    printf '%s' "$(openssl rand -base64 18)" > "secrets/$s.txt"
done
```

`make` checks that `srcs/.env` and all six secrets exist before building.

**Domain** — add it to `/etc/hosts`:

```bash
echo "127.0.0.1 <login>.42.fr" | sudo tee -a /etc/hosts
```

## Build and launch

```bash
make
```

This runs, in order:

1. `check`: verifies `srcs/.env` and the secrets.
2. `dirs`: creates `DATA_PATH/{mariadb,wordpress,nginx_logs,goaccess_report}`.
3. `docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build`.

Every image is built from its own Dockerfile and tagged `<service>:inception`, so `latest` is never used. Compose starts the services in dependency order: MariaDB and Redis first, WordPress once MariaDB is healthy, then FTP, and NGINX last because it must resolve the names of the services it proxies.

### What happens on the first start

| Container | Entrypoint actions |
|---|---|
| mariadb | Initializes the data directory, creates the database and user, sets the root password (bootstrap mode, no network), then `exec mysqld` |
| wordpress | Waits for MariaDB, downloads WordPress, creates `wp-config.php`, installs the site, creates both users, enables the Redis cache, fixes ownership, then `exec php-fpm8.2 -F` |
| nginx | Generates the self-signed certificate and `.htpasswd`, validates the configuration, then `exec nginx -g 'daemon off;'` |
| ftp | Generates its TLS certificate, creates the FTP user with UID 33 (same as `www-data`), then `exec vsftpd` |
| goaccess | Opens the shared access log and serves real-time updates over WebSocket |
| redis, static, adminer | Start their daemon directly as `ENTRYPOINT` |

Every step is skipped if its result already exists, so restarts reuse the existing data.

## Manage containers and volumes

### Makefile targets

| Target | Effect |
|---|---|
| `make` / `make up` | Build and start |
| `make down` | Stop and remove containers and network |
| `make logs` | Follow the logs of all services |
| `make clean` | `down` + remove the project images |
| `make fclean` | `clean` + remove volumes and all data in `DATA_PATH` |
| `make re` | `fclean` + `make` |

`clean` and `fclean` only remove this project's images. The base image `debian:bookworm` and the build cache are kept to speed up the next build.

### Useful Docker commands

```bash
# State and logs
docker ps                                  # running containers and health
docker compose -f srcs/docker-compose.yml ps
docker logs -f <container>

# Enter a container
docker exec -it <container> bash

# Rebuild a single service after changing its files
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build <service>

# Check that the main process is PID 1
docker exec <container> cat /proc/1/cmdline | tr '\0' ' '; echo

# Validate configurations
docker exec nginx nginx -t
docker run --rm wordpress:inception php-fpm8.2 -t

# Network and volumes
docker network inspect inception
docker volume ls
docker volume inspect wordpress_data
```

### Service-specific commands

```bash
# MariaDB
docker exec -it mariadb mariadb -u wpuser -p
docker exec mariadb mariadb -u root            # must fail: root needs a password

# WordPress
docker exec wordpress wp user list --allow-root
docker exec wordpress wp plugin list --allow-root
docker exec wordpress wp redis status --allow-root

# Redis
docker exec redis redis-cli ping
docker exec -it redis redis-cli monitor

# FTP audit log
docker exec ftp tail -f /var/log/vsftpd.log
```

### Security checks

```bash
openssl s_client -connect <login>.42.fr:443 -tls1_2 < /dev/null   # connects
openssl s_client -connect <login>.42.fr:443 -tls1_1 < /dev/null   # fails
curl -v http://<login>.42.fr                                     # port 80 closed
curl -k -o /dev/null -w "%{http_code}\n" https://<login>.42.fr/stats/  # 401
```

## Data storage and persistence

All persistent data lives on the host in `DATA_PATH` (`/home/<login>/data`), through four named volumes:

| Volume | Host directory | Mounted in | Contents |
|---|---|---|---|
| `mariadb_data` | `DATA_PATH/mariadb` | mariadb: `/var/lib/mysql` | Database files |
| `wordpress_data` | `DATA_PATH/wordpress` | wordpress: `/var/www/html`<br>nginx: same path, read-only<br>ftp: same path | WordPress code, configuration and uploads |
| `nginx_logs` | `DATA_PATH/nginx_logs` | nginx (writes), goaccess (reads) | NGINX access log |
| `goaccess_report` | `DATA_PATH/goaccess_report` | goaccess (writes), nginx (reads) | Statistics page |

The volumes are named Docker volumes using the `local` driver with bind options, so Docker manages them by name while the files stay in `DATA_PATH`.

### What survives what

| Action | Containers | Images | Data |
|---|---|---|---|
| Container crash or VM reboot | restarted (`restart: always`) | kept | kept |
| `make down` | removed | kept | kept |
| `make clean` | removed | removed | kept |
| `make fclean` | removed | removed | **deleted** |

Data files belong to users inside the containers (`mysql`, `www-data`), so they cannot be deleted by the host user. `make fclean` deletes them from a temporary root container:

```bash
docker run --rm -v $(DATA_PATH):/data debian:bookworm sh -c 'rm -rf /data/*'
```

### Ownership inside the volumes

- `/var/lib/mysql` is owned by `mysql`; the MariaDB entrypoint fixes it on every start.
- `/var/www/html` is owned by `www-data` (UID 33); the WordPress entrypoint fixes it after wp-cli runs as root. The FTP user shares UID 33, so files uploaded by FTP are writable by WordPress and the other way around.

Ownership is fixed in the entrypoints, not in the Dockerfiles, because volumes are mounted at runtime and hide whatever the image contained at that path.