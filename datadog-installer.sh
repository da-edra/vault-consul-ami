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
DD_CONFIG_DIR="/etc/datadog-agent/"
AGENT_CONFIG_DIR="${DD_CONFIG_DIR}conf.d/${AGENT_VAL}.d/conf.yaml"
DATADOG_CONFIG_DIR="${DD_CONFIG_DIR}datadog.yaml"
CONSUL_CONFIG_DIR="/opt/consul/config/default.json"

function configure_timezone() {
    echo 'ZONE="America/Mexico_City"' >> /etc/sysconfig/clock
    sudo ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
}

function install_datadog() {
    DD_AGENT_MAJOR_VERSION=7 DD_API_KEY="$API_KEY" bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
    curl "$AGENT_CONFIG_URL" -o "$AGENT_CONFIG_DIR"
}

function logs_collection() {
    if [ "$AGENT_VAL" != 'consul' ]; then
        return 0
    fi

    local LOGS_CONFIG="logs:
  - type: journald
    path: /var/log/journal/
    include_units:
      - consul.service"

    usermod -a -G systemd-journal dd-agent
    sed -i 's/# logs_enabled: false/logs_enabled: true/g' "$DATADOG_CONFIG_DIR"
    mkdir -p "$DD_CONFIG_DIR"conf.d/journald.d/; echo "$LOGS_CONFIG" > "$_"/conf.yaml
}

function metrics_collection() {
    if [ "$AGENT_VAL" == 'vault' ]; then
        sed -i 's/# detect_leader: false/detect_leader: false/g' "$AGENT_CONFIG_DIR"
        systemctl reload vault
        systemctl restart vault
        return 0
    fi

    local CONSUL_METRICS=(
        '# catalog_checks: false/catalog_checks: true'
        '# network_latency_checks: false/network_latency_checks: true'
        '# self_leader_check: false/self_leader_check: true'
        '# log_requests: false/log_requests: true'
    )

    local DOGSTATSD_CONFIG='"telemetry": { "dogstatsd_addr": "127.0.0.1:8125" }'

    if [ -n "$TLS_FLAG" ]; then
        CONSUL_METRICS+=('http:/https:')
    fi

    for i in "${CONSUL_METRICS[@]}"; do
        sed -i 's/'"$i"'/g' "$AGENT_CONFIG_DIR"
    done

    cp "$CONSUL_CONFIG_DIR" "$CONSUL_CONFIG_DIR".tmp
    jq ". + { $DOGSTATSD_CONFIG }" "$CONSUL_CONFIG_DIR".tmp > "$CONSUL_CONFIG_DIR"
    rm "$CONSUL_CONFIG_DIR".tmp
    systemctl reload consul
    systemctl restart consul
}

configure_timezone
install_datadog
logs_collection
metrics_collection
systemctl restart datadog-agent
netstat -nup | grep "127.0.0.1:8125.*ESTABLISHED"
