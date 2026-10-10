# User documentation

This guide explains how to use the Inception infrastructure: what it provides, how to start and stop it, how to access each service and how to check that everything works.

## Provided services

| Service | Address | What it is for |
|---|---|---|
| WordPress website | `https://ibeltran.42.fr` | The public website |
| WordPress administration | `https://ibeltran.42.fr/wp-admin/` | Write posts, manage users, change settings |
| Infrastructure map | `https://ibeltran.42.fr/static/` | Links to every service and their live status |
| Adminer | `https://ibeltran.42.fr/adminer/` | Browse and edit the database |
| Statistics | `https://ibeltran.42.fr/stats/` | Website traffic in real time |
| FTP server | `ftp://127.0.0.1` (port 21, encryption required) | Upload and download website files |

MariaDB (the database) and Redis (the cache) work in the background and are not reachable directly from outside.

All web addresses use a self-signed certificate: the first time, the browser shows a security warning that must be accepted.

## Start and stop the project

Run these commands from the root of the repository:

| Command | Effect |
|---|---|
| `make` | Start the whole infrastructure (builds it the first time) |
| `make down` | Stop it. Website content, users and database are kept |
| `make` again | Restart it with the same data |

Containers restart automatically if they crash or if the virtual machine reboots.

⚠️ `make fclean` **deletes all data**: posts, users, uploaded files and the database. Use it only to start from scratch.

## Access the website and the administration panel

1. Open `https://ibeltran.42.fr` and accept the certificate warning.
2. To manage the site, open `https://ibeltran.42.fr/wp-admin/` and log in with one of the two WordPress accounts:
   - **Administrator** (`WP_ADMIN_USER`): full control of the site.
   - **Author** (`WP_USER`): can write and publish their own posts.

### Adminer

Adminer and the statistics page ask first for the HTTP password (`STATS_USER` and `stats_password`). Then fill in the Adminer form:

| Field | Value |
|---|---|
| System | MySQL / MariaDB |
| Server | `mariadb` |
| Username | `MYSQL_USER` (`wpuser`) |
| Password | content of `secrets/db_user_password.txt` |
| Database | `wordpress` |

Logging in as `root` from Adminer fails on purpose: the root account only accepts connections from inside the database container.

### FTP

Encryption is mandatory, so use a client with FTPS support (FileZilla with "Require explicit FTP over TLS", or `lftp`):

```bash
lftp -u <FTP_USER> -e "set ftp:ssl-force true; set ssl:verify-certificate no" ftp://127.0.0.1
```

For security, PHP files (`.php`, `.phtml`, `.phar`…) and `.htaccess` / `.user.ini` cannot be uploaded, downloaded or renamed through FTP. After three wrong passwords, the connection is closed.

## Locate and manage credentials

Credentials are split into two places, neither of which is in the git repository:

| File | Contents |
|---|---|
| `srcs/.env` | User names, e-mails, domain and other non-secret settings |
| `secrets/*.txt` | One password per file |

| Secret file | Used for |
|---|---|
| `db_root_password.txt` | MariaDB `root` account |
| `db_user_password.txt` | MariaDB WordPress account (`MYSQL_USER`) |
| `wp_admin_password.txt` | WordPress administrator |
| `wp_user_password.txt` | WordPress author |
| `ftp_password.txt` | FTP account (`FTP_USER`) |
| `stats_password.txt` | HTTP password for `/stats/` and `/adminer/` (`STATS_USER`) |

To read one: `cat secrets/wp_admin_password.txt`.

To change a password:

- **FTP and statistics/Adminer**: edit the file and run `make down && make`. The new password is applied at startup.
- **WordPress users**: change it from the administration panel (Users → Profile). The secret file is only used for the first installation, so update it too to keep it consistent.
- **Database passwords**: they are only applied when the database is created. Changing them requires `make fclean && make`, which deletes all data.

## Check that the services work

**Containers.** All of them should be `Up`, and `mariadb` should show `(healthy)`:

```bash
docker ps
```

**Visual check.** Open `https://ibeltran.42.fr/static/`: each service shows a green dot when it responds, amber when it is protected by a password and red when it is down. "Check now" repeats the test.

**Logs.** If a service is missing or keeps restarting:

```bash
make logs              # all services
docker logs wordpress  # a single one
```

**Quick checks from the terminal:**

```bash
curl -k -o /dev/null -w "%{http_code}\n" https://ibeltran.42.fr   # 200
docker exec redis redis-cli ping                                  # PONG
docker exec wordpress wp user list --allow-root                   # the two WordPress users
```