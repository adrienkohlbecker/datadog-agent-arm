#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euxo pipefail

# version
AGENT_VERSION=6.6.0

# Docker credentials
DOCKER_USERNAME="<YOUR_DOCKER_USERNAME>"
DOCKER_PASSWORD="<YOUR_DOCKER_PASSWORD>"

# build dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python-dev python-virtualenv git curl mercurial bundler

# The agent loads systemd at runtime https://github.com/coreos/go-systemd/blob/a4887aeaa186e68961d2d6af7d5fbac6bd6fa79b/sdjournal/functions.go#L46
# which means it doesn't need to be included in the omnibus build
# but it requires the headers at build time https://github.com/coreos/go-systemd/blob/a4887aeaa186e68961d2d6af7d5fbac6bd6fa79b/sdjournal/journal.go#L27
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
  git am /root/0001-Add-postgresql-and-libffi-dependency-on-ARM-to-datad.patch
  git am /root/0001-Use-omnibus-software-with-patches.patch
  git am /root/0001-Compile-the-process-agent-from-source-within-omnibus.patch
  git am /root/0001-Apply-patches-to-source.patch
  git am /root/0002-Adapt-dockerfile-to-armhf.patch
  git tag "$AGENT_VERSION-armv7"

  # create virtualenv to hold pip deps
  virtualenv $GOPATH/venv
  set +u; source $GOPATH/venv/bin/activate; set -u

  # install build dependencies
  pip install -r requirements.txt

  # build the agent
  invoke -e agent.omnibus-build --base-dir=$HOME/.omnibus --release-version=$AGENT_VERSION

  # build the image
  if [ $DOCKER_USERNAME != "<YOUR_DOCKER_USERNAME>" ]; then
    cd $GOPATH/src/github.com/DataDog/datadog-agent/Dockerfiles/agent
    cp "$HOME/.omnibus/pkg/*.deb" .
    docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
    docker build . -t $DOCKER_USERNAME/datadog-agent:$AGENT_VERSION
    docker push "$DOCKER_USERNAME/datadog-agent:$AGENT_VERSION-armv7"
  fi
)
