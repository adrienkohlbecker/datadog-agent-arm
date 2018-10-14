**DISCLAIMER: This script is not endorsed nor supported by Datadog itself. You're on your own**

This uses a Scaleway C1 instance (bare-metal arm7 box) to compile and package a datadog-agent as close to the official amd64 release as possible.

Known issues:

- running python checks is unsupported as the arm build doesn't support embedding the python interpreter (see: https://github.com/DataDog/datadog-agent/issues/1069)