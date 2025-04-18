# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM certbot/dns-cloudflare:latest

ARG CERTBOT_USER=certbot
ARG CERTBOT_GROUP=certbot
ARG CERTBOT_UID=9999
ARG CERTBOT_GID=9999

ENV CERTBOT_DOMAINS="" \
    CERTBOT_EMAIL="" \
    CERTBOT_KEY_TYPE="ecdsa" \
    CLOUDFLARE_API_TOKEN="" \
    CLOUDFLARE_PROPAGATION_SECONDS="10" \
    DEBUG=false \
    PUID=0 \
    PGID=0 \
    RENEWAL_INTERVAL=43200 \
    REPLACE_SYMLINKS=false \

COPY --chmod=700 entrypoint.sh /entrypoint.sh

RUN apk update && \
    apk add --no-cache shadow su-exec && \
    addgroup -g "${CERTBOT_GID}" "${CERTBOT_GROUP}" && \
    adduser -u "${CERTBOT_UID}" -G "${CERTBOT_GROUP}" -D -H "${CERTBOT_USER}" && \
    mkdir -p /var/log/letsencrypt && \
    chown 700 /var/log/letsencrypt && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD [ -f "/etc/letsencrypt/live/$(echo "$CERTBOT_DOMAINS" | cut -d',' -f1)/fullchain.pem" ]