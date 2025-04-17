FROM influxdb:latest

LABEL maintainer="ariel@weher.net"

RUN apt-get update && apt-get install -y \
    apt-transport-https ca-certificates curl wget \
    libc-ares2 libjson-c5 vim procps gnupg2 lsb-release apt-utils \
    tini mtr tshark tcpdump termshark python3-pip \
    iputils-ping traceroute iputils-tracepath \
    iputils-arping snmp snmpd software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Variables por defecto para el setup (pueden ser overrideadas con -e si querés)
ENV INFLUXDB_USERNAME=ayudala
ENV INFLUXDB_PASSWORD=ayudala
ENV INFLUXDB_ORG=ayudala
ENV INFLUXDB_BUCKET=ayudala
ENV INFLUXDB_RETENTION=30d
ENV INFLUXDB_TOKEN=ayudala

COPY start-influx.sh /start-influx.sh
RUN chmod +x /start-influx.sh

ENTRYPOINT ["/start-influx.sh"]
