*This project has been created as part of the 42 curriculum by ibeltran.*

# Description

**Inception** is a system administration project whose goal is to build a small but complete web infrastructure with Docker, inside a virtual machine. Every service runs in its own container, built from a custom Dockerfile on top of `debian:bookworm` (the penultimate stable Debian release). No ready-made images from Docker Hub are used.

The mandatory part provides a WordPress website served over HTTPS:

| Service | Role |
|---|---|
| **NGINX** | Single entry point of the infrastructure, port 443 only, TLS 1.2 and 1.3 |
| **WordPress + PHP-FPM** | The website, installed and configured automatically with wp-cli |
| **MariaDB** | The WordPress database |

The bonus part adds five extra services:

| Service | Role |
|---|---|
| **Redis** | Object cache for WordPress |
| **FTP (vsftpd)** | FTPS access to the WordPress volume, hardened against uploading executable code |
| **Static website** | An HTML/CSS/JS page with a live status map of the infrastructure |
| **Adminer** | Web interface to manage the database |
| **GoAccess** (service of choice) | Real-time traffic analytics built from the NGINX access logs |

The whole stack starts with a single `make` command, and all data persists across restarts in `/home/ibeltran/data`.

# Instructions

### Requirements

- A Debian or Ubuntu virtual machine.
- Docker Engine, the Docker Compose v2 plugin (`docker compose`), `make` and `git`.
- Your user in the `docker` group, so Docker can be used without `sudo`.

`setup.sh` installs these dependencies and adds the domain to `/etc/hosts`. The rest of the file is a list of manual test commands, not meant to be executed as a script.

### Configuration

Credentials are never stored in the repository. Before the first launch, create them:

```bash
# 1. Non-sensitive configuration
cp srcs/.env.example srcs/.env
# Edit srcs/.env: LOGIN, DATA_PATH, DOMAIN_NAME and the user names

# 2. Passwords, one per file, without trailing newline
mkdir -p secrets
for s in db_root_password db_user_password wp_admin_password \
         wp_user_password ftp_password stats_password; do
    printf '%s' "$(openssl rand -base64 18)" > "secrets/$s.txt"
done

# 3. Make the domain resolve locally
echo "127.0.0.1 ibeltran.42.fr" | sudo tee -a /etc/hosts
```

The WordPress administrator name (`WP_ADMIN_USER`) must not contain `admin` in any form.

### Usage

| Command | Effect |
|---|---|
| `make` | Checks the configuration, creates the data directories, builds the images and starts the containers |
| `make down` | Stops and removes the containers (data is kept) |
| `make logs` | Follows the logs of all services |
| `make clean` | Removes containers, network and project images (data is kept) |
| `make fclean` | Removes everything, including volumes and all data in `DATA_PATH` |
| `make re` | `fclean` followed by `make` |

Once running, the website is available at `https://ibeltran.42.fr`. The certificate is self-signed, so the browser shows a warning that must be accepted. See `USER_DOC.md` for the list of services and `DEV_DOC.md` for technical details.

# Resources

### Documentation

- [Docker documentation](https://docs.docker.com/) — Dockerfile reference, Compose file reference, secrets, networks and volumes
- [NGINX documentation](https://nginx.org/en/docs/) — `ngx_http_ssl_module`, `ngx_http_fastcgi_module`, `ngx_http_proxy_module`, `ngx_http_auth_basic_module`
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — `mariadb-install-db`, bootstrap mode, server system variables
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/) — `core`, `config`, `user`, `plugin`
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [vsftpd manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Redis Object Cache plugin](https://wordpress.org/plugins/redis-cache/)
- [GoAccess manual](https://goaccess.io/man)
- [Adminer](https://www.adminer.org/)

### Use of AI

An AI assistant (Claude, by Anthropic) was used throughout the project as a tutor and reviewer:

- **Learning**: explaining concepts before implementing them (PID 1 and signals, FastCGI, Docker secrets, user namespaces, FTP passive mode, WebSockets).
- **Debugging**: interpreting error messages, such as the MariaDB `io_uring` EPERM error, PHP-FPM configuration parsing errors and vsftpd silent exits.
- **Review**: reviewing the repository to find errors (misplaced shebangs, missing line continuations, unnecessary `chown`) and security weaknesses.
- **Exploring options**: comparing alternatives for the bonus service and for hardening the FTP server.
- **Documentation**: drafting this README, `USER_DOC.md` and `DEV_DOC.md`.

Every configuration was tested in the virtual machine, and every design choice described below was understood and validated before being kept.

# Project description

### Architecture

```
                          Virtual machine
 ┌──────────────────────────────────────────────────────────────────┐
 │                     Docker network "inception"                   │
 │ :443 ─▶ NGINX ──FastCGI──▶ WordPress (php-fpm) ──▶ MariaDB       │
 │           │                     └────────────────▶ Redis         │
 │           ├──FastCGI──▶ Adminer ─────────────────▶ MariaDB       │
 │           ├──HTTP─────▶ Static website                           │
 │           └──WebSocket▶ GoAccess ◀── NGINX access log            │
 │                                                                  │
 │ :21 + 21100-21110 ─▶ FTP (vsftpd) ──▶ WordPress volume           │
 └──────────────────────────────────────────────────────────────────┘
```

Only NGINX (443) and the FTP server (21 and the passive range) publish ports. MariaDB, WordPress, Redis, Adminer, the static website and GoAccess are only reachable inside the Docker network.

### Main design choices

- **Debian bookworm as base image.** It is the penultimate stable Debian release, as required, and its packages and paths are the most widely documented.
- **One process per container, running as PID 1.** Every entrypoint ends with `exec`, so the daemon replaces the shell, receives signals from `docker stop` directly and shuts down cleanly. No `tail -f`, `sleep infinity` or infinite loops are used.
- **Idempotent entrypoint scripts.** Each initialization step (database creation, WordPress download, configuration, installation, users, certificates) runs only if its result is missing, so containers restart safely and recover from a half-finished first start.
- **Automated WordPress installation.** wp-cli installs WordPress and creates both users (an administrator and an author) without the web installer.
- **Startup ordering with healthchecks.** WordPress waits until MariaDB is healthy, not just started, and its script keeps a bounded wait as a safety net.
- **NGINX as reverse proxy for everything.** Bonus web services are published under paths of the same domain (`/static/`, `/adminer/`, `/stats/`), so they share the TLS configuration and no extra ports are opened.
- **Defense in depth.** FTPS is mandatory, PHP files cannot be uploaded or renamed through FTP, NGINX refuses to execute PHP inside `wp-content/uploads`, brute force is slowed down, and Adminer and the statistics are protected with HTTP basic authentication.

### Virtual Machines vs Docker

A **virtual machine** emulates a complete computer: it has its own virtual hardware and runs its own operating system kernel on top of a hypervisor. It provides strong isolation, but it is heavy (gigabytes of disk, a full boot) and slow to start.

A **Docker container** is an isolated group of processes running directly on the host kernel. Isolation comes from kernel features: namespaces (separate view of processes, network, filesystem and users) and cgroups (resource limits). A container only carries its own userland (libraries and binaries), so it starts in seconds and takes megabytes.

This is why the VM in this project runs Debian 13 while the containers use Debian 12: all of them share the VM kernel, and each container brings its own userland. The two technologies complement each other here: the VM isolates the whole project from the physical machine, and containers isolate the services from each other.

### Secrets vs Environment Variables

**Environment variables** are easy to use, but they are visible in many places: `docker inspect`, `/proc/<pid>/environ`, and every child process inherits them. They can also end up in logs or error reports.

**Docker secrets** are mounted as files in `/run/secrets/` (an in-memory filesystem) only in the containers that declare them. They do not appear in `docker inspect` or in the process environment.

This project uses both: `srcs/.env` holds non-sensitive configuration (domain, database name, user names), and every password lives in `secrets/*.txt`. Scripts read passwords with `cat /run/secrets/...` only when needed. Both `srcs/.env` and `secrets/` are excluded from git.

### Docker Network vs Host Network

With the **host network** (`network: host`), a container shares the network stack of the host: every port it opens is directly exposed, and there is no isolation between containers. It is forbidden by the subject.

A **user-defined bridge network** (`inception`) gives each container its own IP address on a private virtual network, with an embedded DNS server that resolves container names (`mariadb`, `wordpress`, `redis`…). Containers talk to each other freely inside the network, but nothing is reachable from outside unless it is explicitly published with `ports:`. This allows the database to be completely hidden from the outside world while WordPress can still reach it by name.

### Docker Volumes vs Bind Mounts

A **bind mount** maps an arbitrary path of the host into a container. It depends on the host directory structure and is not managed by Docker (it does not appear in `docker volume ls`).

A **named volume** is an object managed by Docker: it has a name, can be listed, inspected and removed with Docker commands, and is declared once in the Compose file and shared between services.

The subject requires named volumes whose data is stored in `/home/<login>/data`. This project combines both ideas: the volumes are named and managed by Docker, but use the `local` driver with `type: none, o: bind` options so their content lives in `DATA_PATH`. As a consequence, `docker compose down -v` removes the volume objects but not the files, which is why `make fclean` deletes `DATA_PATH` explicitly.