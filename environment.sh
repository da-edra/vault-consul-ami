#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

function separator() {
    echo ''
    # shellcheck disable=SC2034
    for i in {1..40}
    do
        echo -en "${RED}~${NC}"
    done
    echo ''
}

function banner() {
    TEXT=$CYAN
    BORDER=$YELLOW
    EDGE=$(echo "  $1  " | sed 's/./~/g')

    if [ "$2" == "warn" ]; then
        TEXT=$YELLOW
        BORDER=$RED
    fi

    MSG="${BORDER}~ ${TEXT}$1 ${BORDER}~${NC}"
    echo -e "${BORDER}$EDGE${NC}"
    echo -e "$MSG"
    echo -e "${BORDER}$EDGE${NC}"
}

banner "I'll set your credentials, input will not echo"

if [ -n "$AWS_ACCESS_KEY_ID" ] ; then
    read -rp "Use current AWS_ACCESS_KEY_ID?
Only 'yes' will be accepted to confirm: " use_access_key_id
    if [[ $use_access_key_id == 'yes' ]]; then
        echo -n 'I will use the current AWS_ACCESS_KEY_ID!'
    else
        unset AWS_ACCESS_KEY_ID
    fi
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] ; then
    read -rsp 'Insert AWS_ACCESS_KEY_ID: ' aws_access_key_id
    export AWS_ACCESS_KEY_ID=$aws_access_key_id
fi

separator

if [ -n "$AWS_SECRET_ACCESS_KEY" ] ; then
    read -rp "Use current AWS_SECRET_ACCESS_KEY?
Only 'yes' will be accepted to confirm: " use_secret_access_key
    if [[ $use_secret_access_key == 'yes' ]]; then
        echo -n 'I will use the current AWS_SECRET_ACCESS_KEY!'
    else
        unset AWS_SECRET_ACCESS_KEY
    fi
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    read -rsp 'Insert AWS_SECRET_ACCESS_KEY: ' aws_secret_access_key
    export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
fi

separator

if [ -n "$AWS_DEFAULT_REGION" ] ; then
    read -rp "Use current AWS_DEFAULT_REGION?
Only 'yes' will be accepted to confirm: " use_default_region
    if [[ $use_default_region == 'yes' ]]; then
        echo -n 'I will use the current AWS_DEFAULT_REGION!'
    else
        unset AWS_DEFAULT_REGION
    fi
fi

if [ -z "$AWS_DEFAULT_REGION" ] ; then
    read -rsp 'Insert AWS_DEFAULT_REGION: ' aws_default_region
    export AWS_DEFAULT_REGION=$aws_default_region
fi

separator

bash -i
