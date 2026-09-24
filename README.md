<p align="center">
		<img src="https://raw.githubusercontent.com/serversideup/docker-certbot-dns-cloudflare/main/.github/header.png" width="1200" alt="Docker Images Logo">
</p>
<p align="center">
	<a href="https://github.com/serversideup/docker-certbot-dns-cloudflare/actions/workflows/publish_docker-images-production.yml"><img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/serversideup/docker-certbot-dns-cloudflare/.github%2Fworkflows%2Fpublish_docker-images-production.yml" /></a>
	<a href="https://github.com/serversideup/docker-certbot-dns-cloudflare/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-certbot-dns-cloudflare" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
	<a href="https://community.serversideup.net"><img alt="Discourse users" src="https://img.shields.io/discourse/users?color=blue&server=https%3A%2F%2Fcommunity.serversideup.net"></a>
  <a href="https://serversideup.net/discord"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

# Certbot Cloudflare DNS Docker Container

SSL certificates that renew themselves. Built on the [official Certbot image](https://hub.docker.com/r/certbot/dns-cloudflare) with an improved user experience, this image generates free Let's Encrypt certificates via Cloudflare DNS validation, renews them automatically, and saves them to a volume any container can read — so even applications without Let's Encrypt support get always-valid certificates. No config files, no exposed ports — just set a few environment variables and deploy.

| Docker Image | Size |
|-------------|------|
| [serversideup/certbot-dns-cloudflare](https://hub.docker.com/r/serversideup/certbot-dns-cloudflare) | ![Docker Image Size](https://img.shields.io/docker/image-size/serversideup/certbot-dns-cloudflare/latest?style=flat-square) |

## Base Image

The image is based on `certbot/dns-cloudflare:latest`, providing a stable and up-to-date environment for running Certbot with Cloudflare DNS authentication.

## Features

- Automatic SSL certificate generation and renewal using Let's Encrypt
- No configs needed, this image generates the cloudflare.ini file for you
- Cloudflare DNS authentication for domain validation
- Customizable configuration via environment variables
- Periodic certificate renewal checks
- Windows support (set `REPLACE_SYMLINKS` to `true`)
- Native Docker health checks to ensure the server is running

### Works great for orchestrated deployments

We designed this image to work great in orchestrated deployments like Kubernetes, Docker Swarm, or even in Github Actions. Look how simple the syntax is:

```yaml
  certbot:
    image: serversideup/certbot-dns-cloudflare
    volumes:
      - certbot_data:/etc/letsencrypt
    environment:
      CLOUDFLARE_API_TOKEN: "${CLOUDFLARE_API_TOKEN}"
      CERTBOT_EMAIL: "${CERTBOT_EMAIL}"
      CERTBOT_DOMAINS: "${CERTBOT_DOMAINS}"
      CERTBOT_KEY_TYPE: "rsa"

  volumes:
    certbot_data:
```

## Environment Variables

The following environment variables can be used to customize the Certbot container:

| Variable               | Description                                                         | Default Value |
|------------------------|---------------------------------------------------------------------|---------------|
| `CERTBOT_DOMAINS`      | Comma-separated list of domains for which to obtain the certificate (example: `example.com,www.example.com`) | - |
| `CERTBOT_CERT_NAME`    | Explicit certificate name to update/modify ([See official docs →](https://eff-certbot.readthedocs.io/en/stable/using.html#changing-a-certificate-s-domains)) | - |
| `CERTBOT_EXPAND`       | **DEPRECATED**: Expand existing certificate to add domains (use CERTBOT_CERT_NAME instead, [see official docs →](https://eff-certbot.readthedocs.io/en/stable/using.html#re-creating-and-updating-existing-certificates)) | `false` |
| `CERTBOT_EMAIL`        | **Optional.** Email address for your Let's Encrypt account. If omitted, the container registers with `--register-unsafely-without-email`. This is safe for most setups since [Let's Encrypt no longer sends expiration notification emails](https://letsencrypt.org/2025/06/26/expiration-notification-service-has-ended/). | - |
| `CERTBOT_KEY_TYPE`     | Type of private key to generate                                     | `ecdsa` |
| `CERTBOT_SERVER`       | The ACME server URL                                                 | `https://acme-v02.api.letsencrypt.org/directory` |
| `CERTBOT_DEPLOY_HOOK`  | A command to run after obtaining the certificate          | - |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token for DNS authentication (see below how to create one)                         | - |
| `CLOUDFLARE_CREDENTIALS_FILE` | Path to the Cloudflare credentials file. | `/cloudflare.ini` |
| `CLOUDFLARE_PROPAGATION_SECONDS` | Wait time (in seconds) after setting DNS TXT records before validation. Useful if DNS propagation is slow. | `10` |
| `DEBUG`                | Enable debug mode (prints more information to the console)            | `false`                    |
| `PUID`                 | The user ID to run certbot as                                       | `0`                    |
| `PGID`                 | The group ID to run certbot as                                        | `0`                    |
| `RENEWAL_INTERVAL`     | Interval between certificate renewal checks. Set to `0` to disable renewals and only run once.                         | 43200 seconds (12 hours) |
| `REPLACE_SYMLINKS`     | Replaces symlinks with direct copies of the files they reference (required for Windows) | `false`                    |

### Using a proxy

Certbot is built on Python's [`requests` library, which natively supports the standard proxy environment variables](https://requests.readthedocs.io/en/latest/user/advanced/#proxies) (`HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY`). Both the ACME (Let's Encrypt) traffic and the Cloudflare API calls will respect these variables — no extra configuration required:

```yaml
environment:
  # HTTP proxy
  HTTPS_PROXY: "http://proxy.example.com:3128"
```

SOCKS proxies are also supported (the image ships with [PySocks](https://pypi.org/project/PySocks/)), including authentication:

```yaml
environment:
  # SOCKS5 proxy with authentication.
  # Use the "socks5h" scheme to have the proxy resolve DNS (prevents DNS leaks);
  # use "socks5" if you want DNS resolved locally instead.
  HTTPS_PROXY: "socks5h://username:password@proxy.example.com:1080"
```

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

## Usage

1. Pull the Docker image:
   ```sh
   docker pull serversideup/certbot-dns-cloudflare:latest
   ```

2. Run the container with the required environment variables:

> [!CAUTION]
> Make sure to replace the `-v /path/to/your/certs:/etc/letsencrypt` with a valid path on your host machine.

   ```sh
   docker run \
    -e CERTBOT_DOMAINS="yourdomain.com" \
    -e CERTBOT_EMAIL="your-email@example.com" \
    -e CLOUDFLARE_API_TOKEN="your-cloudflare-api-token" \
    -v /path/to/your/certs:/etc/letsencrypt \
   serversideup/certbot-dns-cloudflare:latest
   ```
> [!TIP]
> For Wildcard Certificates, use the following order for the Docker instance health check: `domain.name, *.domain.name`

3. The container will automatically generate and renew the certificate.

## Resources

- **[Discord](https://serversideup.net/discord)** for friendly support from the community and the team.
- **[GitHub](https://github.com/serversideup/docker-certbot-dns-cloudflare)** for source code, bug reports, and project management.
- **[Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing help directly from the core contributors.

## Contributing

As an open-source project, we strive for transparency and collaboration in our development process. We greatly appreciate any contributions members of our community can provide. Whether you're fixing bugs, proposing features, improving documentation, or spreading awareness - your involvement strengthens the project.

- **Bug Report**: If you're experiencing an issue while using these images, please [create an issue](https://github.com/serversideup/docker-certbot-dns-cloudflare/issues/new/choose).
- **Security Report**: Report critical security issues via [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

Need help getting started? Join our Discord community and we'll help you out!

<a href="https://serversideup.net/discord"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/join-discord.svg" title="Join Discord"></a>

<!-- serversideup-sponsors -->
## Our Sponsors
All of our software is free and open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Become a sponsor"></a></p>

### Platinum Sponsors
<a href="https://sevalla.com"><img src="https://serversideup.net/sponsors/sevalla.png" alt="Sevalla" width="500px"></a>

### Silver Sponsors
<a href="https://giga-infosystems.com"><img src="https://serversideup.net/sponsors/giga-infosystems.png" alt="GiGa infosystems" width="200px"></a>

### Infrastructure Sponsors
These companies give us free access to the tools and infrastructure we use to build, test, and ship our open source projects. Their support helps our entire community.

<a href="https://depot.dev"><img src="https://serversideup.net/sponsors/depot.png" alt="Depot" width="250px"></a>&nbsp;&nbsp;<a href="https://hub.docker.com/u/serversideup"><img src="https://serversideup.net/sponsors/docker.png" alt="Docker" width="250px"></a>
<!-- serversideup-sponsors -->

<!-- serversideup-about -->
## About Us
We're [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers) - a two-person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div> | <div align="center">Jay Rogers</div> |
| --- | --- |
| <div align="center"><a href="https://x.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://x.com/danpastori"><img src="https://serversideup.net/logos/x.svg" title="X" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/logos/github.svg" title="GitHub" width="24px"></a></div> | <div align="center"><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/logos/x.svg" title="X" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/logos/github.svg" title="GitHub" width="24px"></a></div> |

</div>

### Hire Us
Get two senior Laravel experts who deliver quality code with predictable monthly pricing. [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers) have 30+ years of combined experience building scalable Laravel applications.

- **🎯 Complete Laravel expertise** - Full-stack development, CI/CD, database optimization, mobile apps
- **💰 Predictable pricing** - Fixed monthly subscription, no hourly billing surprises, 40%+ savings
- **⚡ Maximum productivity** - 90%+ development time, no meetings, results in days not weeks
- **🛡️ Risk-free** - 7-day money-back guarantee, cancel anytime

**[💬 Discuss Your Project →](https://serversideup.net/hire-us)**

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [X (Twitter)](https://x.com/serversideup)** - You can also follow [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our Products
If you appreciate this project, be sure to check out our other projects.

### 🛠️ Premium
- **[Self-Host Pro](https://selfhostpro.com)**: Sell self-hosted software in minutes.
- **[Spin Pro](https://getspin.pro)**: Production-ready Docker templates for shipping quickly.

### 🌍 Open Source
- **[serversideup/php](https://serversideup.net/open-source/docker-php/)**: Supercharged PHP Docker images, based off the official PHP images. <!-- repo:serversideup/docker-php -->
- **[Spin](https://serversideup.net/open-source/spin/)**: Docker Simplified. Deploy Anywhere. Zero Downtime. Any OS. <!-- repo:serversideup/spin -->
- **[Financial Freedom](https://serversideup.net/open-source/financial-freedom/)**: Open source alternative to Mint, YNAB, and more. <!-- repo:serversideup/financial-freedom -->
- **[AmplitudeJS](https://serversideup.net/open-source/amplitudejs/)**: Customize the design of any element of the HTML5 Audio Player. <!-- repo:521dimensions/amplitudejs -->
- **[webext-bridge](https://serversideup.net/open-source/webext-bridge/)**: Messaging in Web Extensions made easy. Batteries included. <!-- repo:serversideup/webext-bridge -->
- **[serversideup/ansible](https://github.com/serversideup/docker-ansible)**: Run Ansible anywhere with a lightweight and powerful Docker image. <!-- repo:serversideup/docker-ansible -->

### 📚 Books
- **[Building Browser Extensions](https://serversideup.net/products/building-multi-platform-browser-extensions/)**: Build browser extensions for Firefox, Chrome, and more.
- **[Ultimate Guide To Building APIs & SPAs](https://serversideup.net/products/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web and mobile apps from the same codebase.
<!-- serversideup-about -->
