#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

# version
AGENT_VERSION=6.5.2

# build dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python-dev python-virtualenv git curl mercurial bundler

# TODO: validate why this is not handled by omnibus
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

# git needs this to apply the patches with `git am` we don't actually care about the committer name here
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

##########################################
#               MAIN AGENT               #
##########################################

# clone the main agent
git clone https://github.com/DataDog/datadog-agent $GOPATH/src/github.com/DataDog/datadog-agent

(
  cd $GOPATH/src/github.com/DataDog/datadog-agent
  git checkout $AGENT_VERSION
  git am /root/0001-Add-postgresql-dependency-on-ARM-and-pass-environmen.patch
  git am /root/0001-Use-omnibus-software-with-patches.patch
  git am /root/0001-Compile-the-process-agent-from-source-within-omnibus.patch
  git am /root/0001-Disable-datadog-pip.patch
  git am /root/0001-Apply-patches-to-source.patch

  # create virtualenv to hold pip deps
  virtualenv $GOPATH/venv
  set +u; source $GOPATH/venv/bin/activate; set -u

  # install build dependencies
  pip install -r requirements.txt

  # build the agent
  invoke -e agent.omnibus-build --base-dir=$HOME/.omnibus --agent-version=$AGENT_VERSION
)
