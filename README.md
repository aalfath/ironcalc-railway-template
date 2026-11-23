[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/ironcalc-1?utm_medium=integration&utm_source=button&utm_campaign=ironcalc)

# IronCalc on Railway

One-click [IronCalc](https://www.ironcalc.com/) for [Railway](https://railway.com): the open-source spreadsheet engine (Rust + WebAssembly) and its web app, behind a login, with shared workbooks kept on a volume.

**Version:** IronCalc **0.9.1**, built from the official images, pinned by version and digest:

- `ghcr.io/ironcalc/ironcalc-server:0.9.1@sha256:3e30978764d130ba4939218cb9e23b880eb8aac03095a390aea69b629cabdb86`
- `ghcr.io/ironcalc/ironcalc-caddy:0.9.1@sha256:90e6ebda9dd0a46d1910d0c459fb62e961067f5f9575b687268c0f85e51a34c4`

## What the template deploys

One service, **IronCalc**, built from this repo's `Dockerfile`:

| Part | What it does |
|---|---|
| Caddy (from `ironcalc-caddy`) | Serves the web app on `$PORT` (8080), handles basic auth, passes `/api` to the server, answers `/healthz` |
| IronCalc server (from `ironcalc-server`) | Rust/Rocket API on `127.0.0.1:8000`: `.xlsx` import and export, shared workbooks |
| Volume at `/data` | `ironcalc.sqlite`, the database of shared workbooks. Created on first boot |

- Health check: `/healthz` (open, no login). Restart policy: on failure. If Caddy or the server stops, the container exits non-zero, so Railway restarts it.
- Upstream's `/api/list` endpoint, which returns the id of every shared workbook, is closed (404). The web app doesn't use it.
- It uses about 15 MB of RAM and fits Railway's 0.5 GB Free plan.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `IRONCALC_USERNAME` | `admin` | Login user name |
| `IRONCALC_PASSWORD` | `${{secret(32)}}` (generated) | Login password. Empty makes the site public (not recommended) |
| `PORT` | `8080` | Port Caddy listens on; the public domain points here |

After deploy, copy `IRONCALC_PASSWORD` from the service's Variables tab and sign in as `admin`. To change the password, edit the variable and redeploy.

## Where your data lives

- Workbooks you open and edit are saved **in your browser** (IndexedDB), as in upstream IronCalc. Clearing the site data deletes them, so download an `.xlsx` of anything you want to keep.
- **Share** uploads a copy to the server. It is stored in `/data/ironcalc.sqlite` on the volume and keeps working across redeploys. Anyone with the login can open the link read-only.

## Updates

When IronCalc releases a new version, this repo bumps both `FROM` pins and adds an entry to [`CHANGELOG.md`](CHANGELOG.md), with breaking changes listed first. Railway then shows "update available" on your service, and you choose when to apply it. The volume and your variables are kept.

## Run it locally

```sh
docker build -t ironcalc-railway .
docker run --rm -p 8080:8080 -e IRONCALC_PASSWORD=change-me -v ironcalc-data:/data ironcalc-railway
# open http://localhost:8080 and log in as admin / change-me
```

## Licence

IronCalc is dual-licensed MIT / Apache-2.0 by its authors. This wrapper (Dockerfile, Caddyfile, start script) is provided under the same terms.
