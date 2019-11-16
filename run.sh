#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail


if [ "$1" = "arm64" ] || [ "$1" = "armv8" ] ; then

  # ARM64-2GB means you get a bare-metal armv8/arm64 box
  TYPE=ARM64-2GB

elif [ "$1" = "armhf" ] || [ "$1" = "armv7" ] ; then

  # C1 means you get a bare-metal armv7/armhf box
  TYPE=C1

else
  echo "Unsupported arch"
  exit 1
fi

# create the server
SERVER=$(scw create --commercial-type=$TYPE ubuntu-xenial)

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
scw cp 4377.patch $SERVER:/root

# run the build
scw exec $SERVER /root/build.sh

# grab the output
IP=$(scw ps -l | grep $TYPE | sed 's/\s\s\+/|/g' | cut -d'|' -f6)
scp "root@$IP:/root/.omnibus/pkg/*.deb" .
