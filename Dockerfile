# IronCalc for Railway: one service built from the two official IronCalc images.
# Caddy (from the official ironcalc-caddy image) serves the web app on $PORT and
# proxies /api to the IronCalc server (official ironcalc-server image) on 127.0.0.1:8000.
# Shared workbooks live in SQLite on the volume mounted at /data.
FROM ghcr.io/ironcalc/ironcalc-caddy:0.9.1@sha256:90e6ebda9dd0a46d1910d0c459fb62e961067f5f9575b687268c0f85e51a34c4 AS web

FROM ghcr.io/ironcalc/ironcalc-server:0.9.1@sha256:3e30978764d130ba4939218cb9e23b880eb8aac03095a390aea69b629cabdb86

COPY --from=web /usr/bin/caddy /usr/bin/caddy
COPY --from=web /srv /srv
COPY Caddyfile /etc/caddy/Caddyfile
COPY Rocket.toml /app/Rocket.toml
COPY start.sh /usr/local/bin/ironcalc-start
RUN chmod 0755 /usr/local/bin/ironcalc-start \
    && cp /app/ironcalc.sqlite /app/ironcalc.seed.sqlite

ENV PORT=8080 \
    ROCKET_ADDRESS=127.0.0.1 \
    ROCKET_PORT=8000 \
    ROCKET_CONFIG=/app/Rocket.toml \
    ROCKET_WORKERS=2 \
    ROCKET_LOG_LEVEL=normal \
    GOMAXPROCS=2 \
    XDG_CONFIG_HOME=/tmp/caddy/config \
    XDG_DATA_HOME=/tmp/caddy/data \
    IRONCALC_DATA_DIR=/data

WORKDIR /app
EXPOSE 8080
CMD ["/usr/local/bin/ironcalc-start"]
