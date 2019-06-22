#!/bin/bash

set -eu

cd -P -- "$(dirname -- "$0")"

function die() {
  echo "FATAL: $*" 1>&2
  exit 10
}

declare -a configurations=()
declare dry_run=0

while (($# > 0)); do
  case "$1" in
  -n | --dry-run)
    dry_run=1
    ;;
  -*)
    die "Unknown flag: $1"
    ;;
  *)
    config="$(basename "$1" .yaml).yaml"
    if [[ -f $config ]]; then
      if (("${#configurations[@]}" == 0)); then
        configurations=("$config")
      else
        configurations=("${configurations[@]}" "$config")
      fi
    else
      die "Unknown config: $config (derived from from $1)."
    fi
    ;;
  esac
  shift
done

if (("${#configurations[@]}" == 0)); then
  configurations=(*.yaml)
fi
declare -ar configurations
declare -r dry_run

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
for config in ${configurations[@]}; do
  stack_name="$(basename "$config" .yaml)"

  echo "=> checking ${config}..."
  docker-compose -f "$config" config --quiet 2>&1 | (grep -Ev "'(deploy|configs)'" || :)
done

if ((dry_run)); then
  echo "DRY_RUN: skipping deploy"
  exit 0
fi

# Deploy that sucker
for config in ${configurations[@]}; do
  stack_name="$(basename "$config" .yaml)"

  echo "=> deploying ${stack_name}..."
  docker stack deploy --with-registry-auth --prune -c "$config" "$stack_name"
done

# EOF
