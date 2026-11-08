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

## License / branding

Piwigo is distributed by its upstream authors under **GPL-2.0**. The container image is the official image from Docker Hub (`linuxserver/piwigo:version-16.4.0`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

PHP's built-in server is single-threaded. It is fine for a personal/family gallery but not for high-traffic or heavy batch imports.
The internal MariaDB uses an empty root password. It is only reachable on the compose network, but do not publish the database port or move the app to an untrusted network.
The installer must be completed manually. Until then, the web UI redirects to `/install.php`.
Some Piwigo plugins/themes that write into `/app/www/public/plugins` or `/themes` may not persist; the base gallery and admin UI work with the built-in themes.
Plain HTTP on the LAN; do not expose the published port to the internet without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
