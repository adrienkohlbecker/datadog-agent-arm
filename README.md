**UPDATE: As of December 3rd, 2019, Datadog has official support for ARMv8 https://www.datadoghq.com/blog/datadog-arm-agent/. ARMv7, also provided by this project, remains unofficially supported.**

**DISCLAIMER: This script is not endorsed nor supported by Datadog itself. You're on your own**

```
       .~~.   .~~.
      '. \ ' ' / .'
       .~ .~~~..~.                   ____        __        ____
      : .~.'~'.~. :        _        / __ \____ _/ /_____ _/ __ \____  ____ _
     ~ (   ) (   ) ~     _| |_     / / / / __ `/ __/ __ `/ / / / __ \/ __ `/
    ( : '~'.~.'~' : )   |_   _|   / /_/ / /_/ / /_/ /_/ / /_/ / /_/ / /_/ /
     ~ .~ (   ) ~. ~      |_|    /_____/\__,_/\__/\__,_/_____/\____/\__, /
      (  : '~' :  )                                                /____/
       '~ .~~~. ~'
           '~'
```

## Datadog agent built from source for ARM 32-bit and 64-bit platforms (Raspberry Pi, Scaleway...)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/adrienkohlbecker/datadog-agent-arm)](https://github.com/adrienkohlbecker/datadog-agent-arm/releases/latest) ![GitHub downloads](https://img.shields.io/github/downloads/adrienkohlbecker/datadog-agent-arm/total)

### TL;DR

ARM packages for the datadog-agent are available in the release page https://github.com/adrienkohlbecker/datadog-agent-arm/releases

If you don't trust the artifact that I built (realistically you probably shouldn't install a random deb in your infrastructure), instructions for a reproducible build are provided below. The build takes 3 hours but runs completely unattended.

### Description

This uses a Scaleway C1 instance (bare-metal armv7 box), or a ARM64-2GB instance (bare-metal armv8 box) to compile and package a [datadog-agent](https://github.com/DataDog/datadog-agent) deb as close to the official amd64 release as possible.

Using a scaleway box means you can benefit from their SSD volumes and avoid cloning hundreds of source code repos and thousands of small files on your pi's sd card, which would take ages. It also makes the build process easily reproducible and self-contained, and avoids cluttering your pi with build dependencies.

You get as output a .deb file aimed to be as close as possible to the official release (comes with configs, systemd units, ...)

At the time of writing the agent release was 6.15.0, which is what this was tested with.

### Known issues

- (`armv7`/`armhf`) The trace agent makes heavy use of atomic.*Int64 class of functions, which all panic on 32 bits architectures. I was able to fix the process agent here https://github.com/DataDog/datadog-process-agent/pull/198 but for trace I think somebody from Datadog would be better equipped to make the right choices, given the amount of call sites.
- The `aerospike` and `ibm_mq` don't build on ARM and are thus blacklisted.
- The `python3` runtime is disabled because of an issue with the build: `Could not fetch URL https://pypi.org/simple/wheel/: There was a problem confirming the ssl certificate: HTTPSConnectionPool(host='pypi.org', port=443): Max retries exceeded with url: /simple/wheel/ (Caused by SSLError("Can't connect to HTTPS URL because the SSL module is not available.")) - skipping`

### Patches

We apply patches from the following PRs, pending an official release:
- https://github.com/DataDog/datadog-agent/pull/4377: Build system-probe from the agent omnibus recipe

### How to use:

```shell
# install scaleway cli
$ brew install scw

# login to scaleway
$ scw login

# clone the gist
$ git clone https://github.com/adrienkohlbecker/datadog-agent-arm.git
$ cd datadog-agent-arm

# run the build for armv7/armhf
$ ./run.sh armhf

# run the build for armv8/arm64
$ ./run.sh arm64

# this will leave a .deb in the current directory
$ find . -name "*.deb"
./datadog-agent_6.15.0~ak-1_armhf.deb
```
