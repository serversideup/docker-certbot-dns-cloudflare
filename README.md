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

This container is used to generate and automatically renew SSL certificates from Let's Encrypt using the Cloudflare DNS plugin. It's based off the [official Certbot image](https://hub.docker.com/r/certbot/dns-cloudflare) with some modifications to make it more flexible and configurable.

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

## Our Sponsors
All of our software is free an open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Sponsors"></a></p>

### Black Level Sponsors
<a href="https://sevalla.com"><img src="https://serversideup.net/wp-content/uploads/2024/10/sponsor-image.png" alt="Sevalla" width="546px"></a>

#### Bronze Sponsors
<!-- bronze -->No bronze sponsors yet. <a href="https://github.com/sponsors/serversideup">Become a sponsor →</a><!-- bronze -->

#### Individual Supporters
<!-- supporters --><a href="https://github.com/GeekDougle"><img src="https://github.com/GeekDougle.png" width="40px" alt="GeekDougle" /></a>&nbsp;&nbsp;<a href="https://github.com/JQuilty"><img src="https://github.com/JQuilty.png" width="40px" alt="JQuilty" /></a>&nbsp;&nbsp;<a href="https://github.com/MaltMethodDev"><img src="https://github.com/MaltMethodDev.png" width="40px" alt="MaltMethodDev" /></a>&nbsp;&nbsp;<!-- supporters -->

## About Us
We're [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers) - a two person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div>                  | <div align="center">Jay Rogers</div>                                 |
| ----------------------------- | ------------------------------------------ |
| <div align="center"><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                        | <div align="center"><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                                       |

</div>

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [Twitter](https://twitter.com/serversideup)** - You can also follow [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our products
If you appreciate this project, be sure to check out our other projects.

### 📚 Books
- **[The Ultimate Guide to Building APIs & SPAs](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web & mobile apps from the same codebase.
- **[Building Multi-Platform Browser Extensions](https://serversideup.net/building-multi-platform-browser-extensions/)**: Ship extensions to all browsers from the same codebase.

### 🛠️ Software-as-a-Service
- **[Bugflow](https://bugflow.io/)**: Get visual bug reports directly in GitHub, GitLab, and more.
- **[SelfHost Pro](https://selfhostpro.com/)**: Connect Stripe or Lemonsqueezy to a private docker registry for self-hosted apps.

### 🌍 Open Source
- **[AmplitudeJS](https://521dimensions.com/open-source/amplitudejs)**: Open-source HTML5 & JavaScript Web Audio Library.
- **[Spin](https://serversideup.net/open-source/spin/)**: Laravel Sail alternative for running Docker from development → production.
- **[Financial Freedom](https://github.com/serversideup/financial-freedom)**: Open source alternative to Mint, YNAB, & Monarch Money.
