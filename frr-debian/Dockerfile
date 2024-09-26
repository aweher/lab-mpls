FROM debian:bookworm
LABEL maintainer="ariel@weher.net"

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && \
    apt-get install -y libpcre3-dev apt-transport-https ca-certificates less curl wget logrotate \
    libc-ares2 libjson-c5 vim procps libreadline-dev gnupg2 lsb-release apt-utils \
    libprotobuf-c-dev protobuf-c-compiler tini mtr tshark tcpdump termshark \
    iputils-ping traceroute iputils-tracepath iputils-arping && rm -rf /var/lib/apt/lists/*

RUN curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
RUN echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | tee -a /etc/apt/sources.list.d/frr.list

RUN apt-get update && \
    apt-get install -y frr frr-pythontools frr-rpki-rtrlib && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/frr
RUN chown -R frr:frr /etc/frr /var/run/frr

ENTRYPOINT ["/usr/bin/tini", "--"]

COPY --chmod=0755 docker-start /usr/lib/frr/docker-start
CMD ["/usr/lib/frr/docker-start"]