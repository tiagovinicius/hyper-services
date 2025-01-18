# Function to handle fleet unit simulation
create_fleet_unit() {
  local service_name="$1"
  local workdir="$2"

  # Generate unique base name for the fleet unit
  local base_name="${service_name}-$(uuidgen | cut -c1-8)"
  local node_name="${base_name}-node"

  echo "Creating and starting fleet unit simulation: $node_name"
  run_service "$service_name" "$workdir" hyperservice-fleet-simulator-image "$node_name"

  echo "Accessing fleet unit simulation: $node_name"
  echo "Debug: Listing all containers before waiting for $node_name"
  docker ps -a

  echo "Debug: Waiting for container $node_name to be ready..."
  wait_for_docker "$node_name" 60

  echo "Debug: Listing all containers after waiting for $node_name"
  docker ps -a
  docker exec "$node_name" echo "Container $node_name is ready for docker exec" || echo "Debug: docker exec failed for $node_name"
  if [[ $? -eq 0 ]]; then
    echo "Fleet unit is ready. Starting hyperservice: $base_name"
    docker cp /workspace/apps/hyperservice/utils/service_utils.sh "$node_name":/
    docker cp /workspace/apps/hyperservice/utils/docker_utils.sh "$node_name":/
    docker exec \
      "$node_name" bash -c "source /service_utils.sh && source /docker_utils.sh && run_service \"$service_name\" \"$workdir\" hyperservice-dataplane-image \"$base_name\""

  else
    echo "Failed to connect to fleet unit: $node_name"
  fi
}