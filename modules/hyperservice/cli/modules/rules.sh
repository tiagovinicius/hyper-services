#!/bin/bash

rules=(
  "mesh --help|Displays help information for mesh actions."
  "service --help|Displays help information for service actions."
  "--help|Displays default help information."
  "mesh up|'mesh up' must be used to start the service mesh."
  "mesh --services up|'mesh --services up' must be used to start the service mesh and all services."
  "mesh down|'mesh down' must be used to stop the service mesh and all services."
  "mesh --clean down|'mesh down' must be used to stop the service mesh and all services."
  "--workdir=\$WORKDIR \$NAME start|'start' action requires --workdir and <name> for service."
  "--workdir=\$WORKDIR --recreate \$NAME start|'start' action requires --workdir and <name> for service."
  "--workdir=\$WORKDIR --node=\$NODE_NAME --recreate \$NAME start|'start' action requires --workdir and <name> for service."
  "--workdir=\$WORKDIR --node=\$NODE_NAME \$NAME start|'start' action requires --workdir and <name> for service."
  "\$NAME stop|'up' action requires <name> for service."
  "\$NAME clean|'clean' action requires <name> for service."
  "\$NAME exec|'exec' action requires <name> for service."
  "\$NAME logs|'logs' action requires <name> for service."
  "ls|'service ls' must be used to list all services with specific details."
  "service up|'service up' must be used to start all services in the workspace."
  "service --recreate up|'service up' must be used to remove, recreate and start all services in the workspace."
  "service down|'service down' must be used to stop all hyperservices in the workspace."
  "service --clean down|'service down' must be used to stop and remove all hyperservices in the workspace."
)

validate_workdir_rule() {
  if [[ -z "$WORKDIR" && ( "$ACTION" == "start" || "$ACTION" == "restart" ) ]]; then
    echo "Error: --workdir is required for 'start' and 'restart' actions." >&2
    exit 1
  fi
}