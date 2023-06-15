#!/bin/bash
#
# Start up a kind cluster, install kube-prometheus-stack chart and kafka chart
#
cd "$(dirname "$BASH_SOURCE")"
set -e

function title() {
  echo
  echo "##############################################################################"
  echo "# $1"
  echo "##############################################################################"
}
# get kind
if [ ! -x "./kind" ]; then
  title "Download kind binary"
	[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-amd64
	chmod a+x kind
fi
title "create cluster"
export KUBECONFIG="kind-kubeconfig.yml"
./kind create cluster --name scraper-test-cluster --config=kind-cluster.yaml --wait 5m --image kindest/node:v1.26.3

# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
title "install kube-prometheus-stack chart"
./helm_wrapper.sh repo add prometheus-community https://prometheus-community.github.io/helm-charts
./helm_wrapper.sh repo update
./helm_wrapper.sh install -f values-kube-prometheus-stack.yaml \
                          kube-prometheus-stack \
													prometheus-community/kube-prometheus-stack \
													--create-namespace --namespace monitoring \
													--version 46.8.0
echo "Wait until grafana is up and running . . ."
./kubectl_wrapper.sh wait --namespace monitoring \
													 --for=condition=ready pod \
													 --selector=app.kubernetes.io/name=grafana \
													 --timeout=3m

# https://github.com/bitnami/charts/tree/main/bitnami/kafka/#installing-the-chart
title "install kafka chart"
./helm_wrapper.sh install -f values-kafka.yaml \
                          kafka-bitnami \
													oci://registry-1.docker.io/bitnamicharts/kafka \
													--create-namespace --namespace my-namespace \
													--version 22.1.3
echo "Wait until kafka is up and running . . ."
./kubectl_wrapper.sh wait --namespace monitoring \
													 --for=condition=ready pod \
													 --selector=app.kubernetes.io/name=kafka \
													 --timeout=3m
