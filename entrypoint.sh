#!/bin/sh

function assert() {
  [[ $1 -ne $2 ]] && echo "Program failed with exit code $1" && exit $rc
}

function ensure_certs {
  [ -f /etc/ssl/certs/server.crt ] && [ -f /etc/ssl/private/server.pem ] && return 0
  cd /etc/ssl
  echo Generating self-signed CA
  certtool --generate-privkey --bits=4096 --outfile /etc/ssl/private/ca.pem
  cat > ca.tmpl <<-EOCA
  cn = "ocserv CA"
  organization = "unknown"
  serial = 1
  expiration_days = 999
  ca
  signing_key
  cert_signing_key
  crl_signing_key
EOCA
  certtool --generate-self-signed --load-privkey /etc/ssl/private/ca.pem --template ca.tmpl --outfile /etc/ssl/certs/ca.crt
  echo Generating self-signed server certificate
  certtool --generate-privkey --bits=4096 --outfile /etc/ssl/private/server.pem
  cat > server.tmpl <<-EOSRV
  cn = "ocserv"
  organization = "Unknown"
  expiration_days = 999
  signing_key
  encryption_key
  tls_www_server
EOSRV
  certtool --generate-certificate \
    --load-privkey /etc/ssl/private/server.pem \
    --load-ca-certificate /etc/ssl/certs/ca.crt \
    --load-ca-privkey /etc/ssl/private/ca.pem \
    --template server.tmpl \
    --outfile /etc/ssl/certs/server.crt
  assert $? 0
  return 0
}

function gen_user {
  [ -f "/etc/oc.passwd" ] && return 0
  echo "Generating default ocserv user"
  PASSWORD=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13`
  echo $PASSWORD | ocpasswd -c /etc/oc.passwd ocserv
  assert $? 0
  echo "RANDOM PASSWORD: $PASSWORD"
  return 0
}

function config_iptables {
  echo "Configuring iptables"
  [[ -f /etc/network/iptables.up.rules ]] && echo "Apllying iptables" && iptables-restore -v < /etc/network/iptables.up.rules
  [[ -f /etc/ocserv/iptables.v4.rules ]] && echo "Applying custom iptables rules" && iptables-restore -v < /etc/ocserv/iptables.v4.rules
  [[ $ENABLE_NAT ]] && echo "Enabling NAT" && iptables -t nat -A POSTROUTING -j MASQUERADE
  return 0
}

function update_config {
  echo "Updating configuration"
  [[ ! -z $DEFAULT_DOMAIN ]] && sed -iback -e "s/default-domain = .*/default-domain = $DEFAULT_DOMAIN/" /etc/ocserv/ocserv.conf
  return 0
}

function init {
  # Check certs
  ensure_certs; assert $? 0

  # Generate User
  gen_user; assert $? 0

  echo "Ensuring ipv4 ip forward"
  assert `sysctl -n net.ipv4.ip_forward` 1

  config_iptables; assert $? 0

  echo "Enable TUN device"
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 600 /dev/net/tun

  # Update config
  update_config; assert $? 0

  return 0
}

init; assert $? 0
(
  set -x;
  # Run OpennConnect Server
  exec "$@"
); assert $? 0
