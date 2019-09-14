#!/bin/bash

set -eu

declare -ra gerf_add=(
  letsencrypt.well-known-mount=true

  swarmpit.swarmpit-data=true
  swarmpit.swarmpit-logs=true

  xbrowsersync.db-data=true
)

declare -ra gerf_rm=(
  portainer.portainer-data=true
)

### MAIN

for label in "${gerf_rm[@]}"; do
  docker node update --label-rm "${label}" gerf.org || :
done

for label in "${gerf_add[@]}"; do
  docker node update --label-add "${label}" gerf.org
done

# EOF
