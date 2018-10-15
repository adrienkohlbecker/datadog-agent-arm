**DISCLAIMER: This script is not endorsed nor supported by Datadog itself. You're on your own**

# Build the datadog-agent release for your Raspberry Pi

This uses a Scaleway C1 instance (bare-metal arm7 box) to compile and package a [datadog-agent](https://github.com/DataDog/datadog-agent) deb as close to the official amd64 release as possible.

Using a scaleway box means you can benefit from their SSD volumes and avoid cloning hundreds of source code repos and thousands of small files on your pi's sd card, which would take ages. It also makes the build process easily reproducible and self-contained, and avoids cluttering your pi with build dependencies.

You get as output a .deb file aimed to be as close as possible to the official release (comes with configs, systemd units, ...)

At the time of writing the agent release was 6.5.2, which is what this was tested with.

## Known issues

- running python checks is unsupported as the arm build doesn't support embedding the python interpreter (see: https://github.com/DataDog/datadog-agent/issues/1069)
- we apply the patch from this PR https://github.com/DataDog/datadog-process-agent/pull/198 while waiting for an official release (preventing the process agent from raising a nil pointer exception)

## How to use:

```shell
# install scaleway cli
$ brew install scw

# login to scaleway
$ scw login

# clone the gist
$ git clone https://github.com/adrienkohlbecker/datadog-agent-armv7.git
$ cd datadog-agent-armv7

# run the build
$ ./run.sh

# this will leave a .deb in the working directory
$ find . -name "*.deb"
./datadog-agent_1%3a6.5.2-1_armhf.deb
```
