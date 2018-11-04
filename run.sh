#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

# create the server
# C1 means you get a bare-metal armv7 box
# debian stretch is the base OS for raspbian
SERVER=$(scw create --commercial-type=C1 ubuntu-xenial)

# ensure we drop the server at the end
rm_server() {
  scw rm -f $SERVER
}
trap rm_server EXIT

# start the server
scw start $SERVER

# wait for it to boot
scw exec --wait $SERVER /bin/true

# copy the files
scw cp build.sh $SERVER:/root
scw cp 0001-Add-postgresql-and-libffi-dependency-on-ARM-to-datad.patch $SERVER:/root
scw cp 0001-Apply-patches-to-source.patch                              $SERVER:/root
scw cp 0001-Use-omnibus-software-with-patches.patch                    $SERVER:/root
scw cp 0001-Compile-the-process-agent-from-source-within-omnibus.patch $SERVER:/root
scw cp 0001-Fix-build-failure-on-32bit-armv7.patch                     $SERVER:/root
scw cp 0002-Adapt-dockerfile-to-armhf.patch                            $SERVER:/root

# run the build
scw exec $SERVER /root/build.sh

# grab the output
IP=$(scw ps -l | grep C1 | sed 's/\s\s\+/|/g' | cut -d'|' -f6)
scp "root@$IP:/root/.omnibus/pkg/*.deb" .
