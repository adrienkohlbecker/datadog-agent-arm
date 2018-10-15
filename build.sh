#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

AGENT_VERSION=$1

export DEBIAN_FRONTEND=noninteractive

# snmp-mibs-downloader is in the non-free repo
apt-add-repository non-free
apt-get update

# build dependencies
apt-get install -y python-pip python-virtualenv git curl pkg-config apt-transport-https mercurial rake libssl-dev

# snmp check
apt-get install -y libsnmp-base libsnmp-dev snmp-mibs-downloader

# systemd log tailing
apt-get install -y libsystemd-dev

# Install Go
(
  cd /usr/local
  curl -OL https://dl.google.com/go/go1.11.1.linux-armv6l.tar.gz
  echo "bc601e428f458da6028671d66581b026092742baf6d3124748bb044c82497d42  go1.11.1.linux-armv6l.tar.gz" | sha256sum -c -
  tar -xf go1.11.1.linux-armv6l.tar.gz
  rm go1.11.1.linux-armv6l.tar.gz
)
export PATH=$PATH:/usr/local/go/bin

# set up gopath and environment
mkdir -p "/opt/agent/go/src" "/opt/agent/go/pkg" "/opt/agent/go/bin"
export GOPATH=/opt/agent/go
export PATH=$GOPATH/bin:$PATH

mkdir -p $GOPATH/src/github.com/DataDog

##########################################
#               MAIN AGENT               #
##########################################

# clone the main agent
git clone https://github.com/DataDog/datadog-agent $GOPATH/src/github.com/DataDog/datadog-agent

(
  cd $GOPATH/src/github.com/DataDog/datadog-agent
  git checkout $AGENT_VERSION

  # create virtualenv to hold pip deps
  virtualenv $GOPATH/venv
  set +u; source $GOPATH/venv/bin/activate; set -u

  # install build dependencies
  pip install -r requirements.txt
  invoke -e deps

  # build the agent
  # can't bundle cpython on arm 32 bits https://github.com/DataDog/datadog-agent/issues/1069
  invoke -e agent.build --build-exclude=cpython
)

##########################################
#              TRACE AGENT               #
##########################################

git clone https://github.com/DataDog/datadog-trace-agent $GOPATH/src/github.com/DataDog/datadog-trace-agent

(
  cd $GOPATH/src/github.com/DataDog/datadog-trace-agent
  git checkout $AGENT_VERSION

  make install
)

##########################################
#             PROCESS AGENT              #
##########################################

git clone https://github.com/DataDog/datadog-process-agent $GOPATH/src/github.com/DataDog/datadog-process-agent

(
  cd $GOPATH/src/github.com/DataDog/datadog-process-agent
  git checkout $AGENT_VERSION
  git am /root/0001-Don-t-use-atomic-64-bit-variants.patch

  rake deps
  rake build
)

##########################################
#               BUILD DEB                #
##########################################

(
  cd $HOME

  # download official amd64 deb
  apt-key adv --keyserver keyserver.ubuntu.com --recv 382E94DE
  echo 'deb [arch=amd64] "https://apt.datadoghq.com" stable 6' > /etc/apt/sources.list.d/datadog.list
  apt-get update
  apt-get download datadog-agent:amd64=1:${AGENT_VERSION}-1
  rm /etc/apt/sources.list.d/datadog.list
  apt-get update

  # extract it
  dpkg-deb -R datadog-agent_1%3a${AGENT_VERSION}-1_amd64.deb buildroot

  # remove amd64 bits
  rm -rf buildroot/opt
  rm -rf buildroot/usr

  # install our own stuff
  install -v -D -m 755 "$GOPATH/src/github.com/DataDog/datadog-process-agent/process-agent"   buildroot/opt/datadog-agent/embedded/bin/process-agent
  install -v -D -m 755 "$GOPATH/bin/trace-agent"                                              buildroot/opt/datadog-agent/embedded/bin/trace-agent
  install -v -D -m 755 "$GOPATH/src/github.com/DataDog/datadog-agent/bin/agent/agent"         buildroot/opt/datadog-agent/bin/agent/agent
  install -v -D -m 755 "$GOPATH/src/github.com/DataDog/datadog-agent/bin/agent/dd-agent"      buildroot/usr/bin/dd-agent
  mkdir -p                                                                                    buildroot/opt/datadog-agent/run

  # also copy agent dist folder
  # roughly from https://github.com/DataDog/datadog-agent/blob/6.5.2/omnibus/config/software/datadog-agent.rb#L60-L66
  rsync -vah --exclude conf.d --exclude datadog.yaml --exclude trace-agent.conf $GOPATH/src/github.com/DataDog/datadog-agent/bin/agent/dist buildroot/opt/datadog-agent/bin/agent/

  # fixup the metadata
  # dynamic libraries dependencies:
  # ldd buildroot/opt/datadog-agent/bin/agent/agent:
  # - libsnmp30
  # - libc6
  # - libssl1.1
  # - libssl1.0.2
  # - zlib1g
  # ldd buildroot/opt/datadog-agent/embedded/bin/trace-agent:
  # - libc6
  # ldd buildroot/opt/datadog-agent/embedded/bin/process-agent:
  # - libc6
  echo "Depends: libsnmp30, libc6, libssl1.1, libssl1.0.2, zlib1g" >> buildroot/DEBIAN/control
  sed -i "s/Architecture: amd64/Architecture: armhf/" buildroot/DEBIAN/control

  # regenerate md5sums
  (
    cd buildroot
    md5sum $(find * -type f -not -path 'DEBIAN/*') > DEBIAN/md5sums
  )

  # re-package the deb
  dpkg-deb -b buildroot datadog-agent_1%3a${AGENT_VERSION}-1_armhf.deb

)
