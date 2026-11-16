
#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="/home/ubuntu/devops-microservices-assignment"
PROJECT_NAME="devops-microservices-assignment"
ECR_REGISTRY="877270729691.dkr.ecr.us-east-1.amazonaws.com"
LOCK_FILE="/tmp/devops-microservices-rollback.lock"

SERVICES=(user-service product-service order-service)
TARGET_TAG="${1:-}"

if [[ -z "$TARGET_TAG" || ! "$TARGET_TAG" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
  echo "Usage: $0 <image-tag> [--confirm]"
  exit 2
fi

if [[ "${2:-}" != "--confirm" ]]; then
  echo "DRY RUN: No containers have been changed."
  echo "Requested target tag: $TARGET_TAG"
  echo "To permit a live deployment, supply --confirm."
  exit 0
fi

# Prevent simultaneous rollback script executions.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "ERROR: Another rollback is already running."
  exit 1
fi

cd "$PROJECT_DIR"

compose() {
  local tag="$1"
  shift
  ECR_REGISTRY="$ECR_REGISTRY" IMAGE_TAG="$tag" \
    docker compose -p "$PROJECT_NAME" \
      -f docker-compose.yml \
      -f docker-compose.ecr.yml "$@"
}

declare -A PREVIOUS_IMAGES
declare -A PREVIOUS_IMAGE_IDS

for service in "${SERVICES[@]}"; do
  image=$(docker inspect "$service" --format '{{.Config.Image}}')
  expected_prefix="$ECR_REGISTRY/$service:"

  if [[ "$image" != "$expected_prefix"* ]]; then
    echo "ERROR: Unexpected image for $service: $image"
    exit 1
  fi

  PREVIOUS_IMAGES["$service"]="$image"
  PREVIOUS_IMAGE_IDS["$service"]=$(docker inspect "$service" --format '{{.Image}}')
  echo "Current $service: $image"
done

PREVIOUS_TAG="${PREVIOUS_IMAGES[user-service]##*:}"

for service in "${SERVICES[@]}"; do
  if [[ "${PREVIOUS_IMAGES[$service]##*:}" != "$PREVIOUS_TAG" ]]; then
    echo "ERROR: Services have different deployed tags."
    exit 1
  fi
done

if [[ "$TARGET_TAG" == "$PREVIOUS_TAG" ]]; then
  echo "Target version is already deployed: $TARGET_TAG"
  exit 0
fi

for tag in "$TARGET_TAG" "$PREVIOUS_TAG"; do
  compose "$tag" config --quiet
  for service in "${SERVICES[@]}"; do
    docker image inspect "$ECR_REGISTRY/$service:$tag" >/dev/null || {
      echo "ERROR: Missing image $service:$tag"
      exit 1
    }
  done
done

# Ensure the recovery tag still points to the running image IDs.
for service in "${SERVICES[@]}"; do
  local_id=$(docker image inspect \
    "$ECR_REGISTRY/$service:$PREVIOUS_TAG" \
    --format '{{.Id}}')

  if [[ "$local_id" != "${PREVIOUS_IMAGE_IDS[$service]}" ]]; then
    echo "ERROR: Recovery image ID mismatch for $service."
    exit 1
  fi
done

docker inspect nginx-proxy --format '{{.State.Running}}' | grep -qx true
docker exec nginx-proxy nginx -t

check_health() {
  local service status attempt endpoint

  for service in "${SERVICES[@]}"; do
    for attempt in {1..18}; do
      status=$(docker inspect "$service" \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' \
        2>/dev/null || true)

      if [[ "$status" == "healthy" ]]; then
        echo "$service: healthy"
        break
      fi

      if (( attempt == 18 )); then
        echo "ERROR: $service is not healthy ($status)"
        return 1
      fi

      sleep 5
    done
  done

  for endpoint in / /users /products /orders \
                  /user-health /product-health /order-health; do
    curl --fail --silent --show-error --max-time 10 \
      "http://127.0.0.1$endpoint" -o /dev/null || return 1
    echo "$endpoint: OK"
  done
}

reload_nginx() {
  docker exec nginx-proxy nginx -t || return 1
  docker exec nginx-proxy nginx -s reload || return 1
  sleep 3
}

verify_images() {
  local tag="$1" service actual expected

  for service in "${SERVICES[@]}"; do
    actual=$(docker inspect "$service" --format '{{.Image}}') || return 1

    if [[ "$tag" == "$PREVIOUS_TAG" ]]; then
      expected="${PREVIOUS_IMAGE_IDS[$service]}"
    else
      expected=$(docker image inspect \
        "$ECR_REGISTRY/$service:$tag" \
        --format '{{.Id}}') || return 1
    fi

    if [[ "$actual" != "$expected" ]]; then
      echo "ERROR: Image ID mismatch for $service."
      return 1
    fi
    echo "$service: verified image ID"
  done
}

deploy() {
  local tag="$1"
  echo "Deploying $tag..."

  compose "$tag" up -d --no-build --no-deps "${SERVICES[@]}" || return 1
  reload_nginx || return 1
  check_health || return 1
  verify_images "$tag"
}

echo "Previous version: $PREVIOUS_TAG"
echo "Target version: $TARGET_TAG"

if deploy "$TARGET_TAG"; then
  echo "SUCCESS: $TARGET_TAG passed deployment verification."
  exit 0
fi

echo "WARNING: Target deployment failed."
echo "Attempting recovery to $PREVIOUS_TAG..."

if deploy "$PREVIOUS_TAG"; then
  echo "RECOVERED: $PREVIOUS_TAG is healthy and image IDs verified."
else
  echo "CRITICAL: Automatic recovery failed."
  echo "Manual intervention is required."
fi

exit 1
