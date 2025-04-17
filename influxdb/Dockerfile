FROM influxdb:2.7

LABEL maintainer="ariel@weher.net"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl wget \
  libc-ares2 libjson-c5 vim procps gnupg2 lsb-release apt-utils \
  tini mtr tshark tcpdump termshark python3-pip openssh-server \
  iputils-ping traceroute iputils-tracepath net-tools procps \
  iputils-arping snmp snmpd software-properties-common && \
  rm -rf /var/lib/apt/lists/*

# Crear usuario SSH
RUN useradd -ms /bin/bash influxuser && echo 'admin:admin' | chpasswd
RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

COPY start-influx.sh /start-influx.sh
RUN chmod +x /start-influx.sh

EXPOSE 8086 22
ENTRYPOINT ["/start-influx.sh"]
