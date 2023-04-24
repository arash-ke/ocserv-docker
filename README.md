# ocserv Dockerized

## Description

This is a dockerized version of [OpenConnect server (ocserv)](http://www.infradead.org/ocserv/).

## What is OpenConnect Server?

[OpenConnect server (ocserv)](http://www.infradead.org/ocserv/) is an SSL VPN server. It implements the OpenConnect SSL VPN protocol and also has (currently experimental) compatibility with clients using the [AnyConnect SSL VPN](http://www.cisco.com/c/en/us/support/security/anyconnect-vpn-client/tsd-products-support-series-home.html) protocol.

## Build

Default version that is used for building ocserv is 0.12.1. If you want to change the ocserv version you can pass it using `OC_VERSION` build argument.

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
      - 443:443/tcp
    # volumes:
    #   - "$PWD/config:/etc/ocserv"
```

### Default user

Default config file uses a password file, and a random password will be generated on the first run and logged into the console.
Default user is ocserv.

### Environment Variables

- `ENABLE_NAT` Add masquerade to nat table. Default is false.
- `KEY_BITS` Private key length. Default is 2048
- `AUTO_CONFIG` Update config using template file and environment variables. Default is 1.
- `TCP_PORT` TCP port to listen on. Default is 443.
- `UDP_PORT` UDP port to listen on. Default is 443.
- `SERVER_CERT` Server CERT to use. Default is /etc/ocserv/server.crt.
- `SERVER_KEY` Server private key to use. Default is /etc/ocserv/server.pem.
- `CA_CERT` Server CA to use. Default is /etc/ocserv/ca.crt.
- `MAX_CLIENTS` Maximum clients to accept. Default is 128.
- `MAX_SAME_CLIENTS` Maximum clients to accept. Default is 5.
- `DEFAULT_DOMAIN` Update config to set this domain. Default is empty.
- `IPV4_NETWORK` IPV4 network to use. Default is 10.0.0.1.
- `ROUTE` Route to send to the clients. Default is default.
- `NO_ROUTE` Route to exclude on the clients. Default is 192.168.0.0/23.

### Config files

- `/etc/ocserv/ocserv.conf` ocserv main configuration file.
- `/etc/ocserv/iptables.v4.rules` iptables configration.
- `/etc/ocserv/server.crt` Server certificate file. Will be automatic generated on first run if file not exists
- `/etc/ocserv/server.pem` Server private file. Will be automatic generated on first run if file not exists
- `/etc/ocserv/ca.crt` CA file. Will be automatic generated on first run if file not exists

## References

- [Github project](https://github.com/arash-ke/ocserv-docker)
