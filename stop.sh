#!/bin/bash
#
# Delete the cluster (if running)
#
cd "$(dirname "$BASH_SOURCE")"
set -e

kind delete cluster --name scraper-test-cluster
