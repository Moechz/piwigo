# piwigo-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Piwigo](https://github.com/Piwigo/Piwigo).

## What this is

A four-file TOS Docker application archive (`piwigodocker.tar.gz`) that installs
Piwigo on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `piwigodocker`)
- `piwigodocker.lang` — 23-language superset (TOS requires 14)
- `piwigodocker.svg` — application icon (726 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/piwigo:version-16.4.0`

## How it works

| | |
|---|---|
| Container image | `linuxserver/piwigo:version-16.4.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8023/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/app/www/public/local` → `/Volume1/DockerAppData/piwigodocker/local`, `/app/www/public/_data` → `/Volume1/DockerAppData/piwigodocker/_data`, `/app/www/public/upload` → `/Volume1/DockerAppData/piwigodocker/upload`, `/app/www/public/galleries` → `/Volume1/DockerAppData/piwigodocker/galleries` |
| Logs | `docker logs piwigodocker` (stdout/stderr) |

`galleries` is the photo library; `local` holds `config/database.inc.php` and other site-specific files; `_data` holds compiled templates/cache; `upload` is the temporary upload folder. The internal MariaDB stores albums, users and metadata in `db`. Copying the whole `piwigodocker` folder is a complete backup.

## Privacy

This application runs entirely on your NAS. **The developer does not collect, receive or
have access to any data processed by the application.** There is no telemetry, no analytics
and no account.

| Topic | Detail |
|---|---|
| Data processed | The application's configuration, database, caches and logs, plus any files you create with it. |
| Where it is stored | The application data folder (`/Volume1/DockerAppData/piwigodocker/`) on your NAS. Nothing is uploaded to the developer. |
| Retention period | Until **you** delete it. Logs are rotated or size-limited by the application; uninstalling keeps the data unless you tick “delete data”. |
| Your rights | **Access / export**: copy the data folder. **Correct**: change the values in the web UI. **Delete**: uninstall with “delete data”, or remove the folder after stopping the container. |
| Deletion channel | Delete the folder yourself, or email **moechz@163.com** (answered within 30 days). |
| Security measures | Container runs as uid 1000 (never root), no `privileged`, no host network, no `cap_add`, no Docker socket, one published port; image tag pinned and refreshed on upstream fixes. |
| Children | Not directed at children. |

**Full privacy policy:** [PRIVACY.md](PRIVACY.md) —
<https://github.com/Moechz/piwigo/blob/main/PRIVACY.md> — and the website version at
<https://www.moechz.com/privacy.html>.

## Third-party services (API disclosure)

The developer operates no server in this path. The application contacts only the services
**you configure**, plus (optionally) an update check and the image registry.

| Service | Endpoint | Data sent | Destination / region |
|---|---|---|---|
| Services you configure in the app | the address you enter | only the data that feature needs | normally your own LAN or the provider you chose |
| Update check (if enabled) | the upstream project's release feed | current version string | GitHub, US |
| Image pull | `registry-1.docker.io` or your registry mirror | anonymous pull | Docker Hub, US / your mirror |

See `PRIVACY.md` §6 for the full table. Disable any integration in the app's settings if you
do not want it.

## Licence and attributions

| Component | Licence | Notes |
|---|---|---|
| Piwigo | GPL-2.0 | upstream application, used unmodified inside the image |
| Container image `linuxserver/piwigo:version-16.4.0` | see the image's own metadata | pulled from Docker Hub at install time |
| This packaging | GPL-3.0 (see `LICENSE`) | compose file, metadata, translations, icon |

“Piwigo”, “TerraMaster” and “TOS” are trademarks of their respective owners. This is an
independent community package by Moechz and is not affiliated with the upstream project or
TerraMaster. Full details: [NOTICE.md](NOTICE.md).

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Rootless PHP server.** The LinuxServer image starts s6 as root and symlinks writable folders into the app. `src/entrypoint.sh` runs the unmodified Piwigo code with PHP's built-in server as uid 1000 on 8080; `local/`, `_data/`, `upload/` and `galleries/` are mounted writable and persistent.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Rootless PHP server.** The LinuxServer image runs s6 as root; `src/entrypoint.sh` runs the unmodified Piwigo code with PHP's built-in server as uid 1000 on 8080.
- **Internal MariaDB.** A MariaDB 11.4 sidecar is on the private compose network; only Piwigo publishes a host port. The database uses an empty root password because it is not exposed.
- **Four writable volumes + DB volumes.** `local`, `_data`, `upload`, `galleries`, `db`, `run`.
- **Health check** probes `/` on 8080 (302 redirect to the installer/login page).
- **Fixed image tags**, Docker Hub only, no privileged mode, no host network, no Docker socket.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `local` | Piwigo site config, including local/config/database.inc.php | first run / installer | small | never overwritten; back it up |
| `_data` | compiled templates and cache | first run | bounded by the gallery | safe to clean when the app is stopped |
| `upload` | temporary upload folder | first start | transient | safe to clean |
| `galleries` | the photo library | by the user | grows with every photo | owned by the user; back it up |
| `db` | internal MariaDB data directory | first start | grows with albums/users/metadata | never overwritten; back it up |
| `/Volume1/DockerAppData/piwigodocker/local` | Piwigo application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/piwigodocker/_data` | Piwigo application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/piwigodocker/upload` | Piwigo application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/piwigodocker/galleries` | Piwigo application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/piwigodocker.tar.gz + .sha256
scripts/build.sh 16.4.0-2   # packaging iteration bump
scripts/build.sh 16.4.0-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/piwigodocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v16.4.0-1`**, assets `piwigodocker.tar.gz` +
   `piwigodocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `piwigodocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `16.4.0-1` → automated validation → review.


## Limitations

PHP's built-in server is single-threaded. It is fine for a personal/family gallery but not for high-traffic or heavy batch imports.
The internal MariaDB uses an empty root password. It is only reachable on the compose network, but do not publish the database port or move the app to an untrusted network.
The installer must be completed manually. Until then, the web UI redirects to `/install.php`.
Some Piwigo plugins/themes that write into `/app/www/public/plugins` or `/themes` may not persist; the base gallery and admin UI work with the built-in themes.
Plain HTTP on the LAN; do not expose the published port to the internet without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.

## Support

- Issues and questions: <https://github.com/Moechz/piwigo/issues>
- Email: moechz@163.com
- Privacy: [PRIVACY.md](PRIVACY.md) · Licence: [NOTICE.md](NOTICE.md)
