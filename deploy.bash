#!/bin/bash

set -eu

cd -P -- "$(dirname -- "$0")"

function die() {
  echo "FATAL: $*" 1>&2
  exit 10
}

declare -a configurationss=()

while (($# > 0)); do
  case "$1" in
  -*)
    die "Unknown flag: $1"
    ;;
  *)
    configurations="$(basename "$1" .yaml).yaml"
    if [[ -f $configurations ]]; then
      configurationss=("${configurationss[@]}" $configurations)
    else
      die "Unknown config: $configurations (derived from from $1)."
    fi
    ;;
  esac
  shift
done

if (("${#configurationss[@]}" == 0)); then
  configurationss=(*.yaml)
fi
declare -ar configurationss

# Gather checksums as variables
for path in secrets/*; do
  basename="$(basename "$path" | perl -p -e 'tr/a-z/A-Z/;' -e 's!\W+!_!g;')"
  sum="$(openssl sha256 -r "${path}" | cut -c1-10)"
  value="$(head -n1 "${path}")"

  printf "%36s -> %s(SUM|VALUE) (%s)\n" "$path" "$basename" "$sum"
  eval "export '${basename}SUM=${sum}'"
  eval "export '${basename}VALUE=${value}'"
done

# Verify the configs work
for configurations in ${configurationss[@]}; do
  stack_name="$(basename "$configurations" .yaml)"

  echo "=> checking ${stack_name}..."
  chronic docker-compose -f "$configurations" config
done

# Deploy that sucker
for configurations in ${configurationss[@]}; do
  stack_name="$(basename "$configurations" .yaml)"

  echo "=> deploying ${stack_name}..."
  docker stack deploy --with-registry-auth --prune -c "$configurations" "$stack_name"
done

# EOF
