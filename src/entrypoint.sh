#!/bin/sh
set -e
default_uid=0
default_gid=0
default_unprivileged_user=certbot
default_unprivileged_group=certbot

if [ "$DEBUG" = "true" ]; then
    set -x
fi

################################################################################
# Functions
################################################################################

cleanup() {
    echo "Shutdown requested, exiting gracefully..."
    exit 0
}

debug_print() {
    if [ "$DEBUG" = "true" ]; then
        echo "$1"
    fi
}

configure_uid_and_gid() {
    debug_print "Preparing environment for $PUID:$PGID..."
    
    # Handle existing user with the same UID
    if id -u "${PUID}" >/dev/null 2>&1; then
        old_user=$(id -nu "${PUID}")
        debug_print "UID ${PUID} already exists for user ${old_user}. Moving to a new UID."
        usermod -u "999${PUID}" "${old_user}"
    fi

    # Handle existing group with the same GID
    if getent group "${PGID}" >/dev/null 2>&1; then
        old_group=$(getent group "${PGID}" | cut -d: -f1)
        debug_print "GID ${PGID} already exists for group ${old_group}. Moving to a new GID."
        groupmod -g "999${PGID}" "${old_group}"
    fi

    # Change UID and GID of  run_as user and group
    usermod -u "${PUID}" "${default_unprivileged_user}" 2>&1 >/dev/null || echo "Error changing user ID."
    groupmod -g "${PGID}" "${default_unprivileged_user}" 2>&1 >/dev/null || echo "Error changing group ID."

    # Ensure the correct permissions are set for all required directories
    chown -R "${default_unprivileged_user}:${default_unprivileged_group}" \
        /etc/letsencrypt \
        /var/lib/letsencrypt \
        /var/log/letsencrypt \
        /opt/certbot
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

is_default_privileges() {
    [ "${PUID:-$default_uid}" = "$default_uid" ] && [ "${PGID:-$default_gid}" = "$default_gid" ]
}

run_certbot() {
    # Ensure the log directory is set to 700
    chmod 700 /var/log/letsencrypt
    chown "${PUID}:${PGID}" /var/log/letsencrypt

    if is_default_privileges; then
        certbot_cmd="certbot"
    else
        certbot_cmd="su-exec ${default_unprivileged_user} certbot"
    fi

    debug_print "Running certbot with command: $certbot_cmd"

    # Add -v flag if DEBUG is enabled
    debug_flag=""
    [ "$DEBUG" = "true" ] && debug_flag="-v"

    $certbot_cmd $debug_flag certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /cloudflare.ini \
        --dns-cloudflare-propagation-seconds "$CLOUDFLARE_PROPAGATION_SECONDS" \
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

# Ensure backwards compatibility with the old CERTBOT_DOMAIN environment variable
if [ -n "$CERTBOT_DOMAIN" ] && [ -z "$CERTBOT_DOMAINS" ]; then
  CERTBOT_DOMAINS=$CERTBOT_DOMAIN
fi

validate_environment_variables

if ! is_default_privileges; then
    configure_uid_and_gid
fi

if [ "$REPLACE_SYMLINKS" = "true" ]; then
    configure_windows_file_permissions
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
dns_wait="${CLOUDFLARE_PROPAGATION_SECONDS:-10}"
echo "🕒 DNS Propagation Wait: $dns_wait seconds"
echo "Let's Encrypt, shall we?"
echo "-----------------------------------------------------------"

# Create Cloudflare configuration file
echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > /cloudflare.ini
chmod 600 /cloudflare.ini
if ! is_default_privileges; then
    chown "${PUID}:${PGID}" /cloudflare.ini
fi

# Check if a command was passed to the container
if [ $# -gt 0 ]; then
    if is_default_privileges; then
        exec "$@"
    else
        exec su-exec "${default_unprivileged_user}" "$@"
    fi
else
    # Run certbot initially to get the certificates
    run_certbot

    # If RENEWAL_INTERVAL is set to 0, do not attempt to renew certificates and exit immediately
    if [ "$RENEWAL_INTERVAL" = "0" ]; then
        echo "Let's Encrypt Renewals are disabled because RENEWAL_INTERVAL=0. Running once and exiting..."
        cleanup
    fi

    # Infinite loop to keep the container running and periodically check for renewals
    while true; do
        # POSIX-compliant way to show next run time
        current_timestamp=$(date +%s)
        next_timestamp=$((current_timestamp + RENEWAL_INTERVAL))
        next_run=$(date -r "$next_timestamp" '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S %z')
        echo "Next certificate renewal check will be at ${next_run}"

        # Store PID of sleep process and wait for it
        sleep "$RENEWAL_INTERVAL" & 
        sleep_pid=$!
        wait $sleep_pid
        wait_status=$?

        # Check if we received a signal (more portable check)
        case $wait_status in
            0) : ;; # Normal exit
            *) cleanup ;;
        esac

        if ! run_certbot; then
            echo "Error: Certificate renewal failed. Exiting."
            exit 1
        fi
    done
fi