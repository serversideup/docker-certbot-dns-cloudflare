# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM certbot/dns-cloudflare:latest

ENV CERTBOT_KEY_TYPE="ecdsa" \
    RENEWAL_INTERVAL=43200

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]