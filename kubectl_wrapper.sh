#!/bin/bash
#
# kubectl dockerized
#
cd "$(dirname "$BASH_SOURCE")"
WD="$(pwd)"
set -e

IMAGE="bitnami/kubectl:1.27"
CLUSTER_CONFIG="kind-kubeconfig.yml"

docker run -i -u $UID --rm --network=host -v $WD/:/work/ -w /work/ -e "KUBECONFIG=$CLUSTER_CONFIG" ${IMAGE} "${@}"
