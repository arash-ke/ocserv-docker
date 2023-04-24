FROM alpine:edge as build
ARG OC_VERSION=0.12.1
RUN apk add --update --virtual .build-depos \
  curl \
  g++ \
  gnutls-dev \
  gpgme \
  libev-dev \
  libnl3-dev \
  libseccomp-dev \
  linux-headers \
  linux-pam-dev \
  lz4-dev \
  make \
  readline-dev \
  tar \
  xz \
  dirmngr

RUN curl -sSL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz
RUN mkdir -p /usr/src/ocserv \
  && tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1
RUN cd /usr/src/ocserv \
  && ./configure --prefix=/app \
  && make \
  && make install

FROM alpine:edge
LABEL org.opencontainers.image.authors="arash-ke <arash@ca-studios.com>"
EXPOSE 443/tcp
EXPOSE 443/udp
RUN apk add --no-cache \
    gnutls-utils \
    iptables \
    libnl3 \
    readline \
    gnutls \
    libev \
    libseccomp \
    linux-pam \
    lz4-libs \
    musl \
    nettle \
    openssl \
    bash
COPY entrypoint.sh /entrypoint.sh
COPY iptables.up.rules /etc/network/iptables.up.rules
RUN mkdir -p /etc/ocserv \
    && chmod +x /entrypoint.sh
WORKDIR /etc/ocserv
COPY ocserv.conf.tmpl /etc/ocserv/ocserv.conf.tmpl
COPY --from=build /app /usr
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
