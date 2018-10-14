**DISCLAIMER: This script is not endorsed nor supported by Datadog itself. You're on your own**

This uses a Scaleway C1 instance (bare-metal arm7 box) to compile and package a datadog-agent as close to the official amd64 release as possible.

Using a scaleway box means you can benefit from their SSD volumes and avoid cloning hundreds of source code repos and thousands of small files on your pi's sd card, which would take ages. It also makes the build process easily reproducible and self-contained, and avoids cluttering your pi with build dependencies.

You get as output a .deb file aimed to be as close as possible to the official release (comes with configs, systemd units, ...)

At the time of writing the agent release was 6.5.2, which is what this was tested with.

# Known issues

- running python checks is unsupported as the arm build doesn't support embedding the python interpreter (see: https://github.com/DataDog/datadog-agent/issues/1069)

# How to use:

```shell
# install scaleway cli
brew install scw

# login to scaleway
scw login

# clone the gist
git clone https://gist.github.com/5d1496353a29b95863876e1600cca5d5.git datadog-agent-armv7
cd datadog-agent-armv7

# run the build (argument is agent version to target)
./run.sh 6.5.2
```
