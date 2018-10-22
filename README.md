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

## Build the datadog-agent release for your Raspberry Pi

### TL;DR

ARM packages for the datadog-agent are available in the release page https://github.com/adrienkohlbecker/datadog-agent-armv7/releases

If you don't trust the artifact that I built (realistically you probably shouldn't install a random deb in your infrastructure), instructions for a reproducible build are provided below. The build takes 3 hours but runs completely unattended.

### Description

This uses a Scaleway C1 instance (bare-metal arm7 box) to compile and package a [datadog-agent](https://github.com/DataDog/datadog-agent) deb as close to the official amd64 release as possible.

Using a scaleway box means you can benefit from their SSD volumes and avoid cloning hundreds of source code repos and thousands of small files on your pi's sd card, which would take ages. It also makes the build process easily reproducible and self-contained, and avoids cluttering your pi with build dependencies.

You get as output a .deb file aimed to be as close as possible to the official release (comes with configs, systemd units, ...)

At the time of writing the agent release was 6.5.2, which is what this was tested with.

### Known issues

- The trace agent makes heavy use of atomic.*Int64 class of functions, which all panic on 32 bits architectures. I was able to fix the process agent here https://github.com/DataDog/datadog-process-agent/pull/198 but for trace I think somebody from Datadog would be better equipped to make the right choices, given the amount of call sites.

### Patches

We apply patches from the following PRs, pending an official release:
- https://github.com/DataDog/datadog-agent/pull/2461: allowing the arm build to embed the python interpreter
- https://github.com/DataDog/datadog-agent/pull/2495: compile the process-agent from source
- https://github.com/DataDog/datadog-agent/pull/2497: add postgresql dependency for psycopg2
- https://github.com/DataDog/datadog-process-agent/pull/198: preventing the process agent from raising a nil pointer exception
- https://github.com/DataDog/omnibus-software/pull/218: compile python with `-fPIC`
- https://github.com/DataDog/omnibus-software/pull/216: add libffi dependency to datadog-pip
- https://github.com/DataDog/omnibus-software/pull/215: update cacerts shasum

### How to use:

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

# this will leave a .deb in the current directory
$ find . -name "*.deb"
./datadog-agent_6.5.2~armv7-1_armhf.deb
```
