#!/bin/bash
set -e

# Esperar a que influxd arranque en background
influxd &

echo "[INFO] Esperando que InfluxDB inicie..."
until curl -s localhost:8086/health | grep -q '"status":"pass"'; do
  sleep 1
done

# Hacer setup si aún no se hizo
if [ ! -f /var/lib/influxdb2/setup.done ]; then
  echo "[INFO] Realizando setup inicial de InfluxDB..."
  influx setup \
    --bucket "$INFLUXDB_BUCKET" \
    --org "$INFLUXDB_ORG" \
    --username "$INFLUXDB_USERNAME" \
    --password "$INFLUXDB_PASSWORD" \
    --token "$INFLUXDB_TOKEN" \
    --retention "$INFLUXDB_RETENTION" \
    --force
  touch /var/lib/influxdb2/setup.done
else
  echo "[INFO] Setup ya realizado anteriormente."
fi

# Mantener el proceso en foreground
wait -n
