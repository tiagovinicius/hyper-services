#!/bin/bash

echo "Setting CONTROL_PLANE_STATUS to initializing"
flock /etc/shared/environment/CONTROL_PLANE_STATUS \
  -c "echo "initializing" > /etc/shared/environment/CONTROL_PLANE_STATUS"

echo "Hooking CONTROL_PLANE_STATUS to stopped when control plane is about to be done"
trap 'flock /etc/shared/environment/CONTROL_PLANE_STATUS -c "echo stopped > /etc/shared/environment/CONTROL_PLANE_STATUS"' SIGTERM SIGINT SIGKILL

echo "Setting WORKSPACE_FOLDER"
flock /etc/shared/environment/WORKSPACE_FOLDER \
  -c "echo $WORKSPACE_FOLDER > /etc/shared/environment/WORKSPACE_FOLDER"
echo "Local workspace folder is $WORKSPACE_FOLDER"

echo "Starting control plane"
kuma-cp run 2>&1 | tee cp-logs.txt &
CONTROL_PLANE_PID=$!
echo "Control plane started with PID: $CONTROL_PLANE_PID"

echo "Waiting for control plane to be running"
timeout=300
elapsed=0
while ! curl -sf http://localhost:5681/ > /dev/null 2>&1; do
  if [ $elapsed -ge $timeout ]; then
    echo "Timeout waiting for control plane to be running."
    kill $CONTROL_PLANE_PID
    exit 1
  fi
  echo "Waiting for control plane to be running..."
  sleep 5
  elapsed=$((elapsed + 5))
done

echo "Setting up control plane CLI"
export CONTROL_PLANE_IP=$(hostname -i)
flock /etc/shared/environment/CONTROL_PLANE_IP \
  -c "echo $CONTROL_PLANE_IP > /etc/shared/environment/CONTROL_PLANE_IP"
CONTROL_PLANE_ADMIN_USER_TOKEN=$(curl http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d)
flock /etc/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN \
  -c "echo $CONTROL_PLANE_ADMIN_USER_TOKEN > /etc/shared/environment/CONTROL_PLANE_ADMIN_USER_TOKEN"
kumactl config control-planes add \
 --name default \
 --address http://localhost:5681 \
 --skip-verify

echo "Applying policies"
POLICIES_DIR="/workspace/.hyperservice/policies"
for FILE in $(ls "$POLICIES_DIR"/*.yml | sort); do
    echo "Applying file $FILE"
    echo "$(envsubst < "$FILE")" | kumactl apply -f -
done

echo "Installing observability"
kumactl install observability > /dev/null

echo "Setting CONTROL_PLANE_STATUS to running"
flock /etc/shared/environment/CONTROL_PLANE_STATUS \
  -c "echo "running" > /etc/shared/environment/CONTROL_PLANE_STATUS"

wait $CONTROL_PLANE_PID
