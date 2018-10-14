#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

AGENT_VERSION=$1

# create the server
# C1 means you get a bare-metal armv7 box
# debian stretch is the base OS for raspbian
SERVER=$(scw create --commercial-type=C1 debian-stretch)

# ensure we drop the server at the end
rm_server() {
  scw rm -f $SERVER
}
trap rm_server EXIT

# start the server
scw start $SERVER

# wait for it to boot
scw exec --wait $SERVER /bin/true

scw cp build.sh $SERVER:/root
scw exec $SERVER /root/build.sh $AGENT_VERSION
scw cp $SERVER:/root/datadog-agent_1%3a${AGENT_VERSION}-1_armhf.deb .
