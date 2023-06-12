#!/bin/bash

cd "$(dirname "$BASH_SOURCE")"
set -e

IMAGE="bitnami/kubectl:1.27"
CLUSTER_CONFIG="kind-kubeconfig.yml"

docker run -it -u $UID --rm --network=host -v $WD/:/work/ -w /work/ -e "KUBECONFIG=$CLUSTER_CONFIG" ${IMAGE} "${@}"
