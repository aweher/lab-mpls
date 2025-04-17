FROM influxdb:latest

LABEL maintainer="ariel@weher.net"

# Variables por defecto para el setup (pueden ser overrideadas con -e si querés)
ENV INFLUXDB_USERNAME=admin
ENV INFLUXDB_PASSWORD=admin123
ENV INFLUXDB_ORG=ayudala
ENV INFLUXDB_BUCKET=telegraf
ENV INFLUXDB_RETENTION=30d
ENV INFLUXDB_TOKEN=admin123

COPY start-influx.sh /start-influx.sh
RUN chmod +x /start-influx.sh

ENTRYPOINT ["/start-influx.sh"]
