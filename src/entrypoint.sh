#!/bin/sh

################################################################################
# Functions
################################################################################

cleanup() {
    echo "Shutdown requested, exiting gracefully..."
    exit 0
}

configure_windows_file_permissions() {
    # Permissions must be created after volumes have been mounted; otherwise, windows file system permissions will override
    # the permissions set within the container.
    mkdir -p /etc/letsencrypt/accounts /var/log/letsencrypt /var/lib/letsencrypt
    chmod 755 /etc/letsencrypt /var/lib/letsencrypt
    chmod 700 /etc/letsencrypt/accounts /var/log/letsencrypt
}

# Workaround https://github.com/microsoft/wsl/issues/12250 by replacing symlinks with direct copies of the files they
# reference.
replace_symlinks() {
    target_dir="$1"

    # Iterate over all items in the directory
    for item in "$target_dir"/*; do
        if [ -L "$item" ]; then
            # If the item is a symlink
            target=$(readlink -f "$item")
            if [ -e "$target" ]; then
                echo "Replacing symlink $item with a copy of $target"
                cp -r "$target" "$item"
            else
                echo "Warning: target $target of symlink $item does not exist"
            fi
        elif [ -d "$item" ]; then
            # If the item is a directory, process it recursively
            replace_symlinks "$item"
        fi
    done
}

run_certbot() {
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /cloudflare.ini \
        -d "$CERTBOT_DOMAINS" \
        --key-type "$CERTBOT_KEY_TYPE" \
        --email "$CERTBOT_EMAIL" \
        --agree-tos \
        --non-interactive \
        --strict-permissions
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error: certbot command failed with exit code $exit_code"
        exit 1
    fi

    if [ "$REPLACE_SYMLINKS" = "true" ]; then
      replace_symlinks "/etc/letsencrypt/live";
    fi
}

validate_environment_variables() {
    # Validate required environment variables
    for var in CLOUDFLARE_API_TOKEN CERTBOT_DOMAINS CERTBOT_EMAIL CERTBOT_KEY_TYPE; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var environment variable is not set"
            exit 1
        fi
    done
}

################################################################################
# Main
################################################################################

trap cleanup TERM INT

validate_environment_variables

if [ "$REPLACE_SYMLINKS" = "true" ]; then
    configure_windows_file_permissions
fi

# Ensure backwards compatibility with the old CERTBOT_DOMAIN environment variable
if [ -n "$CERTBOT_DOMAIN" ] && [ -z "$CERTBOT_DOMAINS" ]; then
  CERTBOT_DOMAINS=$CERTBOT_DOMAIN
fi

cat << "EOF"
 ____________________
< Certbot, activate! >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
EOF

echo "🚀 Let's Get Encrypted! 🚀"
echo "🌐 Domain(s): $CERTBOT_DOMAINS"
echo "📧 Email: $CERTBOT_EMAIL"
echo "🔑 Key Type: $CERTBOT_KEY_TYPE"
echo "⏰ Renewal Interval: $RENEWAL_INTERVAL seconds"
echo "Let's Encrypt, shall we?"
echo "-----------------------------------------------------------"

# Create Cloudflare configuration file
echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > /cloudflare.ini

# Run certbot initially to get the certificates
run_certbot

# Infinite loop to keep the container running and periodically check for renewals
while true; do
    # POSIX-compliant way to show next run time
    current_timestamp=$(date +%s)
    next_timestamp=$((current_timestamp + RENEWAL_INTERVAL))
    next_run=$(date -r "$next_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')
    echo "Next certificate renewal check will be at ${next_run}"

    # Use wait with timeout to allow for signal interruption
    sleep "$RENEWAL_INTERVAL" & 
    wait $!

    # Check if we received a signal
    if [ $? -gt 128 ]; then
        cleanup
    fi

    if ! run_certbot; then
        echo "Error: Certificate renewal failed. Exiting."
        exit 1
    fi
done