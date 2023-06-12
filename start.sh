#!/bin/bash

cd "$(dirname "$BASH_SOURCE")"
set -e

# get kind
if [ ! -x "./kind" ]; then
	[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-amd64
	chmod a+x kind
fi
# create cluster
export KUBECONFIG="kind-kubeconfig.yml"
kind create cluster --name scraper-test-cluster --config=kind-cluster.yaml --wait 5m
