#!/bin/bash
#
# helm dockerized
#
cd "$(dirname "$BASH_SOURCE")"
WD="$(pwd)"
set -e

IMAGE="alpine/helm:3.12.0"
CLUSTER_CONFIG="kind-kubeconfig.yml"

docker run -it -u $UID --rm --network=host -v ${WD}/:/work/ -w /work/ -e "KUBECONFIG=$CLUSTER_CONFIG" -e "HOME=/work" ${IMAGE} "${@}"
