# Cloudflare SSL for Unraid

This container is intended for requesting Let's Encrypt certificates using certbot and DNS Challenge via the Cloudflare API in order to make Unraid available via a trusted SSL connecting without the need to expose any ports or run a proxy. This project is based on the work of https://github.com/serversideup/docker-certbot-dns-cloudflare.

| Docker Image | Size |
|-------------|------|
| [tenasi/cloudflaressl](https://hub.docker.com/r/tenasi/cloudflaressl) | ![Docker Image Size](https://img.shields.io/docker/image-size/tenasi/cloudflaressl/latest?style=flat-square) |

## Base Image

The image is based on https://github.com/serversideup/docker-certbot-dns-cloudflare which is based on `certbot/dns-cloudflare:latest`, providing a stable and up-to-date environment for running Certbot with Cloudflare DNS authentication.

## Environment Variables

The following environment variables can be used to customize the Certbot container:

| Variable               | Description                                                         | Default Value |
|------------------------|---------------------------------------------------------------------|---------------|
| `CERTBOT_DOMAINS`      | Comma-separated list of domains for which to obtain the certificate | - |
| `CERTBOT_EMAIL`        | Email address for Let's Encrypt notifications                       | - |
| `CERTBOT_KEY_TYPE`     | Type of private key to generate                                     | `ecdsa` |
| `CERTBOT_SERVER`       | The ACME server URL                                                 | `https://acme-v02.api.letsencrypt.org/directory` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token for DNS authentication (see below how to create one)                         | - |
| `CLOUDFLARE_CREDENTIALS_FILE` | Path to the Cloudflare credentials file. | `/cloudflare.ini` |
| `CLOUDFLARE_PROPAGATION_SECONDS` | Wait time (in seconds) after setting DNS TXT records before validation. Useful if DNS propagation is slow. | `10` |
| `DEBUG`                | Enable debug mode (prints more information to the console)            | `false`                    |
| `PUID`                 | The user ID to run certbot as                                       | `0`                    |
| `PGID`                 | The group ID to run certbot as                                        | `0`                    |
| `RENEWAL_INTERVAL`     | Interval between certificate renewal checks. Set to `0` to disable renewals and only run once.                         | 43200 seconds (12 hours) |
| `REPLACE_SYMLINKS`     | Replaces symlinks with direct copies of the files they reference (required for Windows) | `false`                    |

### Creating a Cloudflare API Token

> [!WARNING]  
> Treat this token like a password. It will grant access to your Cloudflare account and can be used to modify DNS records.

1. Go to the [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) page.
2. Click on "Create Token".
3. Click "Use template" for the "Edit Zone DNS" template.
4. Change the token name (optional)
5. Set a specific zone under "Zone Resources" (optional)
6. Click on "Continue to summary".
7. Click on "Create Token".

