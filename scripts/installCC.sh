#!/bin/bash

# Import Utils file
. scripts/utils.sh

PEER=$1
ORG=$2
CC_NAME=$3
VERSION=${4:-1.0}
LANGUAGE=golang

if [ "$CC_NAME" = "chaincode_example02" ]; then
        CC_SRC_PATH="github.com/chaincode/$CC_NAME/go/"
else
        CC_SRC_PATH="github.com/chaincode/$CC_NAME/"
fi

echo "Installing Chainode: $CC_NAME of version: $VERSION in peer: $PEER org: $ORG"
installChaincode $PEER $ORG $CC_NAME $VERSION 

