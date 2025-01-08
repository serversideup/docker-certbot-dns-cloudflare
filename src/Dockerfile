# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM certbot/dns-cloudflare:latest

ENV CERTBOT_DOMAINS="" \
    CERTBOT_EMAIL="" \
    CERTBOT_KEY_TYPE="ecdsa" \
    CLOUDFLARE_API_TOKEN="" \
    RENEWAL_INTERVAL=43200

COPY --chmod=700 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD [ -f "/etc/letsencrypt/live/$(echo "$CERTBOT_DOMAINS" | cut -d',' -f1)/fullchain.pem" ]