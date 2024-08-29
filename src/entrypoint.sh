#!/bin/sh
# Validate required environment variables
for var in CLOUDFLARE_API_TOKEN CERTBOT_DOMAIN CERTBOT_EMAIL CERTBOT_KEY_TYPE; do
    if [ -z "$(eval echo \$$var)" ]; then
        echo "Error: $var environment variable is not set"
        exit 1
    fi
done

# Create Cloudflare configuration file
echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > /cloudflare.ini

# Function to run certbot with provided arguments
run_certbot() {
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /cloudflare.ini \
        -d "$CERTBOT_DOMAIN" \
        --key-type "$CERTBOT_KEY_TYPE" \
        --email "$CERTBOT_EMAIL" \
        --agree-tos \
        --non-interactive
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error: certbot command failed with exit code $exit_code"
        exit 1
    fi
}

# Run certbot initially
run_certbot

# Infinite loop to keep the container running and periodically check for renewals
while true; do
    echo "Next certificate renewal check will be in ${RENEWAL_INTERVAL} seconds"
    sleep "$RENEWAL_INTERVAL"
    if ! run_certbot; then
        echo "Error: Certificate renewal failed. Exiting."
        exit 1
    fi
done