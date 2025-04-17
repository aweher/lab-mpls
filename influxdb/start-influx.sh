#!/bin/bash
set -e

# Generar credenciales si no existen
INFLUXDB_USERNAME=${INFLUXDB_USERNAME:-"admin"}
INFLUXDB_PASSWORD=$(openssl rand -hex 12)
INFLUXDB_ORG=$(openssl rand -hex 16)
INFLUXDB_BUCKET=$INFLUXDB_ORG
INFLUXDB_TOKEN=$(openssl rand -hex 32)

echo "[INFO] Iniciando sshd..."
/usr/sbin/sshd

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

  mkdir -p /var/lib/influxdb2/shared
  cat <<EOF > /var/lib/influxdb2/shared/creds.env
INFLUXDB_URL=http://influx:8086
INFLUXDB_USERNAME=$INFLUXDB_USERNAME
INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD
INFLUXDB_ORG=$INFLUXDB_ORG
INFLUXDB_BUCKET=$INFLUXDB_BUCKET
INFLUXDB_TOKEN=$INFLUXDB_TOKEN
EOF

  touch /var/lib/influxdb2/setup.done
  echo "[INFO] Credenciales generadas:"
  cat /var/lib/influxdb2/shared/creds.env
fi

wait -n
