FROM influxdb:2.7

LABEL maintainer="ariel@weher.net"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl wget \
  libc-ares2 libjson-c5 vim procps gnupg2 lsb-release apt-utils \
  tini mtr tshark tcpdump termshark python3-pip net-tools procps \
  iputils-ping traceroute iputils-tracepath net-tools procps \
  iputils-arping snmp snmpd software-properties-common && \
  rm -rf /var/lib/apt/lists/*


COPY start-influx.sh /start-influx.sh
RUN chmod +x /start-influx.sh

EXPOSE 8086
ENTRYPOINT ["/start-influx.sh"]
