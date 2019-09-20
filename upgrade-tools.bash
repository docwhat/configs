#!/bin/bash

set -eEuo pipefail

curl -o /usr/local/bin/docker-compose.tmp -sSL https://github.com/docker/compose/releases/latest/download/docker-compose-Linux-x86_64
chmod a+x /usr/local/bin/docker-compose.tmp
mv -fv /usr/local/bin/docker-compose.tmp /usr/local/bin/docker-compose

curl -o /usr/local/bin/gomplate.tmp -sSL https://github.com/hairyhenderson/gomplate/releases/latest/download/gomplate_linux-amd64
chmod a+x /usr/local/bin/gomplate.tmp
mv -fv /usr/local/bin/gomplate.tmp /usr/local/bin/gomplate

# EOF
