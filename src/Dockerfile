FROM certbot/dns-cloudflare:latest

ENV CERTBOT_DOMAIN="" \
    CERTBOT_EMAIL="" \
    CERTBOT_KEY_TYPE="ecdsa" \
    CLOUDFLARE_API_TOKEN="" \
    RENEWAL_INTERVAL=43200

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]