#!/bin/bash
git config --global --add safe.directory /workspace

echo "Installing dependencies"
npm install
npm install --global @moonrepo/cli

echo "Creating directories"
mkdir -p logs


echo "Connecting to mesh"
export CONTAINER_IP=$(hostname -i)
kumactl config control-planes add \
  --name=default \
  --address=http://$CONTROL_PLANE_IP:5681 \
  --auth-type=tokens \
  --auth-conf token=${CONTROL_PLANE_ADMIN_USER_TOKEN}

echo "Applying policies"
POLICIES_DIR="./.hyperservice/policies"
for FILE in $(ls "$POLICIES_DIR"/*.yml | sort); do
    echo "Applying $FILE"
    echo "$(envsubst < "$FILE")" | kumactl apply -f -
done

echo "Setting up dataplane"
kumactl generate dataplane-token --tag kuma.io/service=$DATAPLANE_NAME --valid-for=720h > /.token
useradd -u 5678 -U kuma-dp
kumactl install transparent-proxy \
  --kuma-dp-user kuma-dp \
  --redirect-dns \
  --exclude-inbound-ports 22
runuser -u kuma-dp -- \
  kuma-dp run \
    --cp-address https://$CONTROL_PLANE_IP:5678 \
    --dataplane-token-file=/.token \
    --dataplane="$(envsubst < ./.hyperservice/dataplane.yml)" \
    2>&1 | tee logs/dataplane-logs.txt &


echo "Starting service"
moon $DATAPLANE_NAME:dev \
  2>&1 | tee logs/app-logs.txt