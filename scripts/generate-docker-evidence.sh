#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${1:-fit4110/iot-ingestion:lab04}
CONTAINER_NAME=${2:-fit4110-iot-lab04}
PORT=${3:-8000}
HEALTH_TIMEOUT=${4:-60}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPORTS="$ROOT_DIR/reports"
mkdir -p "$REPORTS"

echo "Building image $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" . 2>&1 | tee "$REPORTS/docker-build.log"

echo "Running container $CONTAINER_NAME..."
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT":8000 --env-file .env.example "$IMAGE_NAME" >/dev/null

HEALTH_URL="http://localhost:$PORT/health"
END_TIME=$(( $(date +%s) + HEALTH_TIMEOUT ))
OK=0
while [ $(date +%s) -lt $END_TIME ]; do
  if curl -sS "$HEALTH_URL" -o "$REPORTS/health.json"; then
    echo "Health check passed:"
    cat "$REPORTS/health.json"
    OK=1
    break
  fi
  sleep 2
done

if [ $OK -eq 0 ]; then
  echo "Health check failed after $HEALTH_TIMEOUT seconds. Collecting container logs."
  docker logs "$CONTAINER_NAME" 2>&1 | tee "$REPORTS/container.log"
  echo "Stopping container..."
  docker stop "$CONTAINER_NAME" || true
  exit 1
fi

echo "Running Newman tests against local container..."
npm run test:local 2>&1 | tee "$REPORTS/newman-local.log"

docker logs "$CONTAINER_NAME" 2>&1 | tee "$REPORTS/container.log"

echo "Stopping container..."
docker stop "$CONTAINER_NAME" || true

cat > "$REPORTS/docker-evidence.md" <<EOF
# Docker Evidence (generated)

- Image: $IMAGE_NAME
- Container: $CONTAINER_NAME

## Build log
reports/docker-build.log

## Health check
reports/health.json

## Newman reports
reports/newman-lab04-local.html
reports/newman-lab04-local.xml

## Container logs
reports/container.log

EOF

echo "Evidence written to $REPORTS/docker-evidence.md"