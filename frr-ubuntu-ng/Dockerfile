FROM ubuntu:noble
LABEL maintainer="ariel@weher.net"

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV INFLUXDB_URL=http://influxdb:8086
ENV INFLUXDB_TOKEN=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX
ENV INFLUXDB_ORG=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX
ENV INFLUXDB_BUCKET=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX

# Dependencias generales + snmp + herramientas de red
RUN apt-get update && apt-get install -y \
    libpcre3-dev apt-transport-https ca-certificates curl wget logrotate \
    libc-ares2 libjson-c5 vim procps libreadline-dev gnupg2 lsb-release apt-utils \
    libprotobuf-c-dev protobuf-c-compiler tini mtr tshark tcpdump termshark \
    iputils-ping traceroute iputils-tracepath iputils-arping \
    snmp snmpd software-properties-common && rm -rf /var/lib/apt/lists/*

# Instalar repositorio de InfluxData y Telegraf
RUN curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key && \
    echo "943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515  influxdata-archive.key" | sha256sum -c - && \
    cat influxdata-archive.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdata-archive.gpg && \
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' > /etc/apt/sources.list.d/influxdata.list && \
    apt-get update && \
    apt-get install -y telegraf && \
    rm -rf /var/lib/apt/lists/*

# Instalar FRR desde su repositorio oficial
RUN curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
RUN echo "deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" > /etc/apt/sources.list.d/frr.list

RUN apt-get update && apt-get install -y frr frr-pythontools && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/frr   
RUN chown -R frr:frr /etc/frr /var/run/frr

# Copiar configuraciones
COPY snmpd.conf /etc/snmp/snmpd.conf
COPY telegraf.conf.template /etc/telegraf/telegraf.conf.template
COPY telegraf.conf /etc/telegraf/telegraf.conf
COPY --chmod=0755 docker-start /usr/lib/frr/docker-start

COPY docker-start /usr/local/bin/docker-start
RUN chmod +x /usr/local/bin/docker-start
ENTRYPOINT ["/usr/local/bin/docker-start"]
