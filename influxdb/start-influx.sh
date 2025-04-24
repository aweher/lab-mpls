#!/bin/bash
set -e

# Generar credenciales si no existen
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=ayuda.la
INFLUXDB_ORG=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX
INFLUXDB_BUCKET=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX
INFLUXDB_TOKEN=9TwbWJmvKqnLtsFkUJxtpvuAUeNpnUrX

echo "[INFO] Iniciando influxd en background..."
influxd &

echo "[INFO] Esperando que InfluxDB esté disponible..."
until curl -s localhost:8086/health | grep -q '"status":"pass"'; do
  sleep 1
done

if [ ! -f /var/lib/influxdb2/setup.done ]; then
  echo "[INFO] Realizando setup inicial..."

  influx setup \
    --bucket "$INFLUXDB_BUCKET" \
    --org "$INFLUXDB_ORG" \
    --username "$INFLUXDB_USERNAME" \
    --password "$INFLUXDB_PASSWORD" \
    --token "$INFLUXDB_TOKEN" \
    --retention 30d \
    --force

  touch /var/lib/influxdb2/setup.done
  echo "[INFO] InfluxDB configurado correctamente."
fi

wait -n
