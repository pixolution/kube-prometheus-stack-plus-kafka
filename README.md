# kube-prometheus-stack-plus-kafka

Minimal example of starting a kind cluster, install the [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
and [`kafka` helm chart](https://github.com/bitnami/charts/tree/main/bitnami/kafka/#installing-the-chart) both into the same namespace `monitoring`. The way of
adding additional scrape configs to prometheus changed this year to this:
* https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/proposals/202212-scrape-config.md

But I cannot get it to work, please help!

The script `start.sh` contains all steps to reproduce the issue (`stop.sh` deletes the cluster). Make sure the
tools `curl` and `netcat` are installed:
```
./start.sh
```

All resources init without issues, check with:
```
watch ./kubectl_wrapper.sh get all -A
```

The `kube-prometheus-stack` is installed with a [`values.yaml`](./values-kube-prometheus-stack.yaml)
that sets the following serviceMonitor values:
```
   [ . . . ]
prometheus:
  enabled: true
  serviceMonitorSelector:
    matchLabels:
      prometheus: "true"
  serviceMonitorNamespaceSelector: {}
  serviceMonitorSelectorNilUsesHelmValues: true
   [ . . . ]
```

The `kafka` chart uses a [`values.yaml`](./values_kafka.yaml) to enable metric
export (both, kafka metric endpoint and JMX):
```
   [ . . . ]
metrics:
  kafka:
    enabled: true
  jmx:
    enabled: false
  serviceMonitor:
    enabled: true
    labels:
      prometheus: "true"
```

The `kafka`helm charts creates the `ServiceMonitor` resources that should add
an additional scrape target to prometheus
```
$ ./kubectl_wrapper.sh get servicemonitor -n monitoring
NAME                                             AGE
kafka-bitnami-metrics                             2m
kube-prometheus-stack-alertmanager                2m
kube-prometheus-stack-apiserver                   2m
kube-prometheus-stack-coredns                     2m
kube-prometheus-stack-grafana                     2m
kube-prometheus-stack-kube-controller-manager     2m
kube-prometheus-stack-kube-etcd                   2m
kube-prometheus-stack-kube-proxy                  2m
kube-prometheus-stack-kube-scheduler              2m
kube-prometheus-stack-kube-state-metrics          2m
kube-prometheus-stack-kubelet                     2m
kube-prometheus-stack-operator                    2m
kube-prometheus-stack-prometheus                  2m
kube-prometheus-stack-prometheus-node-exporter    2m
```

Details of `kafka-bitnami-metrics`
```
$ ./kubectl_wrapper.sh describe servicemonitor -n monitoring kafka-bitnami-metrics
Name:         kafka-bitnami-metrics
Namespace:    monitoring
Labels:       app.kubernetes.io/component=cluster-metrics
              app.kubernetes.io/instance=kafka-bitnami
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=kafka
              helm.sh/chart=kafka-22.1.3
              prometheus=true
Annotations:  meta.helm.sh/release-name: kafka-bitnami
              meta.helm.sh/release-namespace: monitoring
API Version:  monitoring.coreos.com/v1
Kind:         ServiceMonitor
Metadata:
  Creation Timestamp:  2023-06-12T09:27:57Z
  Generation:          1
  Resource Version:    1209
  UID:                 1a6e72f0-c68c-4b68-97e5-505549cad9cc
Spec:
  Endpoints:
    Path:     /metrics
    Port:     http-metrics
  Job Label:  app.kubernetes.io/name
  Namespace Selector:
    Match Names:
      monitoring
  Selector:
    Match Labels:
      app.kubernetes.io/component:  cluster-metrics
      app.kubernetes.io/instance:   kafka-bitnami
      app.kubernetes.io/name:       kafka
Events:                             <none>
```

But they do not show up in the list of scrape targets in prometheus. The other
`ServiceMonitor` resources are all available, but `kafka` is not part of the list:
```
./list-active-scrape-configs.sh
Run kubectl in background to proxy to prometheus . . .
Found no pod, search for service . . .
Found service "service/kube-prometheus-stack-prometheus"

##############################################################################
# Press "ctrl + c" to quit
##############################################################################
 - http://127.0.0.1:9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090

List of active scrape targets from prometheus API:
http://localhost:9090/api/v1/targets

Handling connection for 9090
"kube-prometheus-stack-alertmanager"
"http://10.244.2.3:9093/metrics"
"kubernetes"
"https://172.19.0.4:6443/metrics"
"kube-prometheus-stack-coredns"
"http://10.244.0.3:9153/metrics"
"kube-prometheus-stack-coredns"
"http://10.244.0.2:9153/metrics"
"kube-prometheus-stack-kube-controller-manager"
"https://172.19.0.4:10257/metrics"
"kube-prometheus-stack-kube-etcd"
"http://172.19.0.4:2381/metrics"
"kube-prometheus-stack-kube-proxy"
"http://172.19.0.2:10249/metrics"
"kube-prometheus-stack-kube-proxy"
"http://172.19.0.3:10249/metrics"
"kube-prometheus-stack-kube-proxy"
"http://172.19.0.4:10249/metrics"
"kube-prometheus-stack-kube-proxy"
"http://172.19.0.5:10249/metrics"
"kube-prometheus-stack-kube-scheduler"
"https://172.19.0.4:10259/metrics"
"kube-prometheus-stack-kube-state-metrics"
"http://10.244.3.3:8080/metrics"
"kube-prometheus-stack-kubelet"
"https://172.19.0.5:10250/metrics"
"kube-prometheus-stack-kubelet"
"https://172.19.0.3:10250/metrics"
"kube-prometheus-stack-kubelet"
"https://172.19.0.4:10250/metrics"
"kube-prometheus-stack-kubelet"
"https://172.19.0.2:10250/metrics"
"kube-prometheus-stack-kubelet"
"https://172.19.0.5:10250/metrics/cadvisor"
"kube-prometheus-stack-kubelet"
"https://172.19.0.3:10250/metrics/cadvisor"
"kube-prometheus-stack-kubelet"
"https://172.19.0.4:10250/metrics/cadvisor"
"kube-prometheus-stack-kubelet"
"https://172.19.0.2:10250/metrics/cadvisor"
"kube-prometheus-stack-kubelet"
"https://172.19.0.4:10250/metrics/probes"
"kube-prometheus-stack-kubelet"
"https://172.19.0.2:10250/metrics/probes"
"kube-prometheus-stack-kubelet"
"https://172.19.0.5:10250/metrics/probes"
"kube-prometheus-stack-kubelet"
"https://172.19.0.3:10250/metrics/probes"
"kube-prometheus-stack-operator"
"https://10.244.3.2:10250/metrics"
"kube-prometheus-stack-prometheus-node-exporter"
"http://172.19.0.2:9100/metrics"
"kube-prometheus-stack-prometheus-node-exporter"
"http://172.19.0.3:9100/metrics"
"kube-prometheus-stack-prometheus-node-exporter"
"http://172.19.0.4:9100/metrics"
"kube-prometheus-stack-prometheus-node-exporter"
"http://172.19.0.5:9100/metrics"
"kube-prometheus-stack-prometheus"
"http://10.244.3.4:9090/metrics"
```

Here the details of a working `ServiceMonitor` definition (`kube-prometheus-stack-alertmanager`):
```
$ ./kubectl_wrapper.sh describe servicemonitor -n monitoring kube-prometheus-stack-alertmanager
Name:         kube-prometheus-stack-alertmanager
Namespace:    monitoring
Labels:       app=kube-prometheus-stack-alertmanager
              app.kubernetes.io/instance=kube-prometheus-stack
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/part-of=kube-prometheus-stack
              app.kubernetes.io/version=46.8.0
              chart=kube-prometheus-stack-46.8.0
              heritage=Helm
              release=kube-prometheus-stack
Annotations:  meta.helm.sh/release-name: kube-prometheus-stack
              meta.helm.sh/release-namespace: monitoring
API Version:  monitoring.coreos.com/v1
Kind:         ServiceMonitor
Metadata:
  Creation Timestamp:  2023-06-12T09:27:14Z
  Generation:          1
  Resource Version:    880
  UID:                 45068302-0674-43e3-bac1-47ffeaa180d1
Spec:
  Endpoints:
    enableHttp2:  true
    Path:         /metrics
    Port:         http-web
  Namespace Selector:
    Match Names:
      monitoring
  Selector:
    Match Labels:
      App:             kube-prometheus-stack-alertmanager
      Release:         kube-prometheus-stack
      Self - Monitor:  true
Events:                <none>
```


Both helm chart are deployed to the same namespace `monitoring`, the
`serviceMonitorSelector` is set to `prometheus: "true"` in `values.yaml` of
prometheus. Why does prometheus not add my scrape config? Found no events or
logs that may help.
