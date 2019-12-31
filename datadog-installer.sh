#!/bin/bash

HELP="Usage: sudo ./datadog-installer.sh <operation> [...]
Automatically install and configure Datadog for Hashicorp's Vault or Consul

operations:
    -k (apikey)  Datadog's API key
    -a <options> install for the specified agent
    -t           install for clusters with TLS

Examples:
$ sudo ./datadog-installer.sh -k 'API Key' -a vault -t
$ sudo ./datadog-installer.sh -k 'API Key' -a CONSUL"

if [ -z "$SUDO_USER" ]; then
    echo "$HELP"
    exit 1
fi

API_KEY=""
AGENT_VAL=""
TLS_FLAG=
while getopts k:a:t OPERATIONS; do
    case $OPERATIONS in
        k) API_KEY=$OPTARG;;
        a) AGENT_VAL=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]');;
        t) TLS_FLAG=1;;
        *) echo "$HELP"
           exit 2;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    echo "$HELP"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "API key can't be blank"
    exit 1
fi

if [ "$AGENT_VAL" != 'vault' ] && [ "$AGENT_VAL" != 'consul' ]; then
    echo "Invalid agent, select 'consul' or 'vault'"
    exit 1
fi

AGENT_CONFIG_URL="https://raw.githubusercontent.com/DataDog/integrations-core/master/${AGENT_VAL}/datadog_checks/${AGENT_VAL}/data/conf.yaml.example"
AGENT_CONFIG_DIR="/etc/datadog-agent/conf.d/${AGENT_VAL}.d/conf.yaml"
DATADOG_CONFIG_DIR="/etc/datadog-agent/datadog.yaml"
LOGS_CONFIG="
  logs:
      - type: file
        path: /var/log/consul_server.log
        source: consul
        service: myservice"

function install_datadog() {
    DD_AGENT_MAJOR_VERSION=7 DD_API_KEY="$API_KEY" bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
    curl "$AGENT_CONFIG_URL" -o "$AGENT_CONFIG_DIR"

    if [ -n "$TLS_FLAG" ] && [ "$AGENT_VAL" == 'consul' ]; then
        sed -i 's/http:/https:/g' "$AGENT_CONFIG_DIR"
    fi

    systemctl restart datadog-agent
}

function log_collection() {
    if [ "$AGENT_VAL" != 'consul' ]; then
        return 0
    fi

    sed -i 's/# logs_enabled: false/logs_enabled: true/g' "$DATADOG_CONFIG_DIR"
    echo "$CONFIGURATION_LOGS" >> "$AGENT_CONFIG_DIR"
    systemctl restart datadog-agent
}

function metrics_collection() {
    sed -i 's/# catalog_checks: false/catalog_checks: true/g' "$AGENT_CONFIG_DIR"
    sed -i 's/# network_latency_checks: false/network_latency_checks: true/g' "$AGENT_CONFIG_DIR"
    sed -i 's/# self_leader_check: false/self_leader_check: true/g' "$AGENT_CONFIG_DIR"
    sed -i 's/# log_requests: false/log_requests: true/g' "$AGENT_CONFIG_DIR"
    systemctl restart datadog-agent
}

install_datadog
log_collection
