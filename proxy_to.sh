#!/bin/bash
#
# Script to establish proxy to service or pod that matches the given label(s)
#
function usage() {
  echo
  echo
  echo "$0 LABEL_SELECTOR PORTS [NAMESPACE]"
  echo "e.g.:"
  echo "$0 \"app=kube-prometheus-stack-prometheus\" \"9090:9090\""
  exit 1
}

function title() {
  echo
  echo "##############################################################################"
  echo "# $1"
  echo "##############################################################################"
}

if [ "$1" == "" ]; then
  usage "Need label(s) to select pod or service. Multiple labels are comma separated."
fi
if [ "$2" == "" ]; then
  usage "Need port(s) to select pod or service. Multiple ports are comma separated."
fi

if [ "$3" == "" ]; then
  NAMESPACE="monitoring"
else
  NAMESPACE="$3"
fi

POD_NAME=$(./kubectl_wrapper.sh get pods --namespace "${NAMESPACE}" -l "$1" -o jsonpath="{.items[0].metadata.name}" 2> /dev/null)
if [ $? -ne 0 ]; then
  echo "Found no pod, search for service . . ."
  POD_NAME="service/"$(./kubectl_wrapper.sh get service --namespace "${NAMESPACE}" -l "$1" -o jsonpath="{.items[0].metadata.name}")
  if [ $? -ne 0 ]; then
    echo "Did not found label(s) \"$1\". Tried service and pods, giving up."
    echo $POD_NAME
    exit 1
  else
    echo "Found service \"$POD_NAME\""
  fi
fi
title "Press \"ctrl + c\" to quit"
while true; do
  for p in $2; do
    PORT="$(echo $p|cut -d: -f1)"
    echo " - http://127.0.0.1:${PORT}"
  done
  ./kubectl_wrapper.sh --namespace "${NAMESPACE}" port-forward $POD_NAME $2
  echo "Connection has been destroyed . . . try again in 5 seconds (use ctrl + c to quit)"
  sleep 5
done
