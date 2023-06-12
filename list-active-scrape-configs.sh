#!/bin/bash
#
# Make sure we have a proxy to the prometheus service, then read the
# list of scrape targets from prometheus API using curl.
#

# Kill background jobs of this process group when exiting
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

# make sure we change workdir into the script parent folder if script is called from another location
cd "$(dirname "$BASH_SOURCE")"

# is localhost:9090 available?
netcat -z localhost 9090 &> /dev/null
if [ "$?" -ne 0 ]; then
	echo "Run kubectl in background to proxy to prometheus . . ."
	./proxy_to.sh "app=kube-prometheus-stack-prometheus" "9090:9090"&
	sleep 3
else
	echo "Found prometheus at localhost:9090"
fi

echo
echo "List of active scrape targets from prometheus API:"
echo "http://localhost:9090/api/v1/targets"
echo
# list the scrape targets from prometheus API parsed with jq
curl -s localhost:9090/api/v1/targets|jq '.data.activeTargets[]| .labels.service, .scrapeUrl'
