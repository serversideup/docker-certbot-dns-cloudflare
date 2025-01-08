# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM certbot/dns-cloudflare:latest

ENV CERTBOT_DOMAINS="" \
    CERTBOT_EMAIL="" \
    CERTBOT_KEY_TYPE="ecdsa" \
    CLOUDFLARE_API_TOKEN="" \
    RENEWAL_INTERVAL=43200

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]