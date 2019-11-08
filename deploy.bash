#!/bin/bash

set -eu

cd -P -- "$(dirname -- "$0")"

function die() {
  echo "FATAL: $*" 1>&2
  exit 10
}

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
    die "Uknown argument: $1"
    ;;
  esac
  shift
done

declare -r dry_run

# Gather checksums as variables
for path in secrets/* configs/*; do
  basename="$(basename "$path" | perl -p -e 'tr/a-z/A-Z/;' -e 's!\W+!_!g;')"
  sum="$(openssl sha256 -r "${path}" | cut -c1-10)"
  value="$(head -n1 "${path}")"

  printf "%36s -> %s(SUM|VALUE) (%s)\n" "$path" "$basename" "$sum"
  eval "export '${basename}SUM=${sum}'"
  eval "export '${basename}VALUE=${value}'"
done

# Build
echo "=> building..."
rm -rf build docker-compose.yaml docker-compose.yml
./process.rb src/*.yaml
mkdir -p build/secrets build/configs
cp -av configs/* build/configs/
cp -av secrets/* build/secrets/
gomplate --input-dir=src --output-dir=build

# Verify the configs work
declare -a config_args=(
  $(ruby -e 'print Dir["build/*.yaml"].reject { |x| x.start_with? "docker-compose." }.map { |x| "--file=#{x}"  }.join("\n")')
  --verbose
  config
)
declare -ar config_args
echo "=> checking..."
(docker-compose "${config_args[@]}" >docker-compose.yaml) 2>&1 | (grep -Ev "Compose does not support" || :)

if ((dry_run)); then
  echo "DRY_RUN: skipping deploy"
  exit 0
fi

echo "=> deploying..."
docker stack deploy \
  --compose-file=docker-compose.yaml \
  --with-registry-auth \
  --resolve-image=changed \
  --prune \
  gerf

# EOF
