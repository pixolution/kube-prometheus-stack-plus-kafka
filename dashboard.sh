#!/bin/bash

function title() {
  echo
  echo "##############################################################################"
  echo "# $1"
  echo "##############################################################################"
}


if [ "$1" == "install" ]; then
  title "Install dashboard in namespace kubernetes-dashboard"
  ./kubectl_wrapper.sh create namespace kubernetes-dashboard
  ./helm_wrapper.sh repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
  ./helm_wrapper.sh repo update
  ./helm_wrapper.sh upgrade --install kubernetes-dashboard \
                             --set metricsScraper.enabled=true \
                             --set nodeSelector.node-type=control-node \
                             --set 'tolerations[0].effect=NoSchedule' \
                             --set 'tolerations[0].key=node-role.kubernetes.io/master' \
                             --set 'tolerations[0].operator=Exists' \
                             --set 'tolerations[1].effect=NoSchedule' \
                             --set 'tolerations[1].key=node-role.kubernetes.io/control-plane' \
                             --set 'tolerations[1].operator=Exists' \
                             --namespace kubernetes-dashboard \
                             kubernetes-dashboard/kubernetes-dashboard \
                             --version 6.0.8
  title "Install dashboard admin user"
  ./kubectl_wrapper.sh apply -f dashboard-user-admin.yaml

  ./kubectl_wrapper.sh wait --namespace kubernetes-dashboard \
                             --for=condition=ready pod \
                             --selector=app.kubernetes.io/name=kubernetes-dashboard \
                             --timeout=90s
elif [ "$1" == "uninstall" ]; then
  title "Uninstall dashboard and namespace kubernetes-dashboard"
  ./helm_wrapper.sh uninstall kubernetes-dashboard --namespace kubernetes-dashboard
  ./kubectl_wrapper.sh delete namespace kubernetes-dashboard
elif [ "$1" == "proxy" ]; then
  title "Dashboard token:"
  ./kubectl_wrapper.sh wait --namespace kubernetes-dashboard \
                             --for=condition=ready pod \
                             --selector=app.kubernetes.io/name=kubernetes-dashboard \
                             --timeout=90s

  ./kubectl_wrapper.sh -n kubernetes-dashboard create token admin-user
  title "Proxy link: (ctrl + c to quit): https://127.0.0.1:10443"
  ./kubectl_wrapper.sh port-forward -n kubernetes-dashboard service/kubernetes-dashboard 10443:443
else
  echo "Need either install, uninstall or proxy as parameter. Got \"$1\""
  echo
  echo "$0 install|uninstall|proxy"
  exit 1
fi
