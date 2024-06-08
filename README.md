# ⌚ gluetun-delay 

[Gluetun](https://github.com/qdm12/gluetun) is a VPN container client that works with a large number of VPN providers, and includes nice features such as built-in DNS across the VPN, VPN port-forwarding support for multiple VPN providers, and more.

This shell script is intended to delay the start of _other_ containers using Gluetun's VPN networking until Gluetun has confirmed it's started. In some configurations, it's possible for containers you _want_ to use VPN to start before Gluetun and skip the VPN entirely.

&nbsp;

### 🤔 Do I need this?

This script might **not** be needed if you're:
* Using `--network=container:gluetun` from the CLI on the attached containers, which ensures that Gluetun has started before those containers can begin to start.
* Using `network_mode: "service:gluetun"` or `network_mode: "container:gluetun"` in Docker Compose files, which also ensures Gluetun starts first.
* Using [Kubernetes Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) in Kubernetes 1.28+, which also ensures Gluetun starts first.
* Using the Gluetun SOCKS proxy - the proxy is only usable once Gluetun starts, so this script wouldn't be needed for this situation.

This script might be **needed** if you're:
* Using `podman` pods: the additional containers in pods can start before Gluetun finishes taking control of the networking.
* Using Kubernetes _without_ Sidecar Containers, which can also allow the additional containers to start before Gluetun and escape the VPN.

&nbsp;

### 🤨 Can I use this script if I'm using the container networking or Kubernetes Sidecar Containers?

Yes, this script will work in these configurations as well, and should provide an additional backstop to ensure Gluetun has taken control of the networking _before_ proceeding with starting your additional containers and applications on the VPN.

&nbsp;

### 😌 Install / Use:

This script is intended to be inserted into the startup for the container you're _attaching_ to Gluetun. The easiest way to use this script is with containers that support custom startup scripts, such as any of LinuxServer.io's containers with the [Custom Scripts](https://docs.linuxserver.io/general/container-customization/#custom-scripts) feature. LinuxServer.io has [a large fleet of containers](https://fleet.linuxserver.io/) available for many apps you might want to use this script with.

Here is an example from [LinuxServer.io's qBittorrent container](https://github.com/linuxserver/docker-qbittorrent) README showing the script in use - once the script is downloaded and mounted into the container, it would run automatically on container start, holding the startup until Gluetun is ready:

#### Docker Compose:
```yaml
---
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8080
      - TORRENTING_PORT=6881
    volumes:
      - /path/to/qbittorrent/appdata:/config
      - /path/to/downloads:/downloads
      # Add the script as a volume into the /custom-cont-init.d folder:
      - /folder/gluetun-delay.sh:/custom-cont-init.d/00-gluetun-delay.sh:ro
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
```

#### Command Line:
```bash
docker run -d \
  --name=qbittorrent \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e WEBUI_PORT=8080 \
  -e TORRENTING_PORT=6881 \
  -p 8080:8080 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -v /path/to/qbittorrent/appdata:/config \
  -v /path/to/downloads:/downloads \
  # Add the script as a volume into the /custom-cont-init.d folder:
  -v /folder/gluetun-delay.sh:/custom-cont-init.d/00-gluetun-delay.sh:ro \
  --restart unless-stopped \
  lscr.io/linuxserver/qbittorrent:latest
```

&nbsp;

### 👀 What does the script do?

* The script checks on Gluetun via the Gluetun API server at `127.0.0.1:8000`, only proceeding once it gets a non-empty result for the Public IP test that Gluetun performs on startup. If it gets no reply from the Gluetun API, or the Public IP is empty, the script will delay until it gets a successful reply from the Gluetun API.
* If the script isn't able to confirm Gluetun is working by checking for a Public IP result, it delays indefinitely; it doesn't exit or try to terminate the container. In the case of LinuxServer.io containers, this holds the startup process until the script finishes.
* The script will also print status messages to the container logs.