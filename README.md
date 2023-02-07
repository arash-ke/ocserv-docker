# ocserv Dockerized

## Description

This is a dockerized version of [OpenConnect server (ocserv)](http://www.infradead.org/ocserv/).

## What is OpenConnect Server?

[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol and also has (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

## Build

The default version that is used for building ocserv is 0.12.1. If you want to change the ocserv version you can pass it using `OC_VERSION` build argument.

```bash
docker build --rm --tag ocserv:0.12.1-alpine .
```

## Run

Running using docker CLI and image in docker hub:

```bash
docker run -d --cap-add=NET_ADMIN -p 443:443 -p 443:443/udp --name ocserv arashke/ocserv:0.12.1-alpine
```

Sample docker-compose file:

```yaml
version: '3.0'
services:
  ocserv:
    image: arashke/ocserv:0.12.1-alpine
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    ports:
      - 443:443/udp
      - 443/tcp
    # volumes:
    #   - "$PWD/config:/etc/ocserv"
```

### Default user

The default config file uses a password file, and a random password will be generated on the first run and logged into the console.
The default user is ocserv.

### Environment Variables

- `ENABLE_NAT` Add masquerade to nat table. The default is false.
- `DEFAULT_DOMAIN` Update config to set this domain. The default is empty.
- `KEY_BITS` Private key length. The default is 2048

### Config files

- `/etc/ocserv/ocserv.conf` ocserv main configuration file.
- `/etc/ocserv/iptables.v4.rules` iptables configration.
- `/etc/ocserv/server.crt` Server certificate file. Will be automatic generated on first run if file not exists
- `/etc/ocserv/server.pem` Server private file. Will be automatic generated on first run if file not exists
- `/etc/ocserv/ca.crt` CA file. Will be automatic generated on first run if file not exists

## References

- [Github project](https://github.com/arash-ke/ocserv-docker)
