#!/bin/bash

function assert() {
  [[ $1 -ne $2 ]] && echo "Program failed with exit code $1" && exit $rc
}

function ensure_certs {
  local cert_path=/etc/ocserv
  local bits=2048
  [[ ! -z "$KEY_BITS" ]] && bits=$KEY_BITS
  cd $cert_path
  [ -f $cert_path/ca.pem ] && [ -f $cert_path/server.crt ] && [ -f $cert_path/server.pem ] && return 0
  if ! [ -f $cert_path/ca.pem ]; then
    echo "Generating CA RSA key > $cert_path/ca.pem"
    certtool --generate-privkey --bits $bits --outfile $cert_path/ca.pem
  fi
  if ! [ -f $cert_path/ca.crt ]; then
    echo "Generating self-signed CA > $cert_path/ca.crt"
    cat > ca.tmpl <<-EOCA
    cn = "ocserv CA"
    organization = "unknown"
    serial = 1
    expiration_days = 9999
    ca
    signing_key
    cert_signing_key
    crl_signing_key
EOCA
    certtool --generate-self-signed --load-privkey $cert_path/ca.pem --template ca.tmpl --outfile $cert_path/ca.crt
    assert $? 0
  fi
  if ! [ -f $cert_path/server.pem ]; then
    echo "Generating server RSA key > $cert_path/server.pem"
    certtool --generate-privkey --bits $bits --outfile $cert_path/server.pem
    assert $? 0
  fi
  if ! [ -f $cert_path/server.crt ]; then
    echo "Generating self-signed server certificate > $cert_path/server.crt"
    cat > server.tmpl <<-EOSRV
    cn = "ocserv"
    organization = "Unknown"
    expiration_days = 999
    signing_key
    encryption_key
    tls_www_server
EOSRV
    certtool --generate-certificate \
      --load-privkey $cert_path/server.pem \
      --load-ca-certificate $cert_path/ca.crt \
      --load-ca-privkey $cert_path/ca.pem \
      --template server.tmpl \
      --outfile $cert_path/server.crt
    assert $? 0
  fi
  return 0
}

function gen_user {
  [ -f "/etc/ocserv/oc.passwd" ] && return 0
  echo "Generating default ocserv user"
  local PASSWORD=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13`
  local pass_hash=`echo $PASSWORD | openssl passwd -5 -in -`
  echo "ocserv:*:$pass_hash" > /etc/ocserv/oc.passwd
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
  echo "=============================="
  local oc_config=$(eval "echo \"$(</etc/ocserv/ocserv.conf.tmpl)\"")
  echo "$oc_config" | tee /etc/ocserv/ocserv.conf
  return 0
}

function init {
  # Check certs
  ensure_certs; assert $? 0
  echo "=============================="
  # Generate User
  gen_user; assert $? 0
  echo "=============================="

  echo "Ensuring ipv4 ip forward"
  assert `sysctl -n net.ipv4.ip_forward` 1
  echo "=============================="

  config_iptables; assert $? 0
  echo "=============================="

  echo "Enable TUN device"
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 600 /dev/net/tun
  echo "=============================="

  # Update config
  [[ ${AUTO_CONFIG:-1} -ne 0 ]] && update_config; assert $? 0
  echo "=============================="

  return 0
}

init; assert $? 0
(
  set -x;
  # Run OpennConnect Server
  exec "$@"
); assert $? 0
