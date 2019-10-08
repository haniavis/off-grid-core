#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build the off-grid network"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
WITH_CHAINCODE="$7"
CC_NAME="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
: ${WITH_CHAINCODE:="no"}
: ${CC_NAME:="chaincode_example02"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10


if [ "$CC_NAME" = "chaincode_example02" ]; then
	CC_SRC_PATH="github.com/chaincode/$CC_NAME/go/"
else
	CC_SRC_PATH="github.com/chaincode/$CC_NAME/"
fi

if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

if [ "$LANGUAGE" = "java" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
fi

#echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
#echo "Creating channel..."
#createChannel

## Join all the peers to the channel
#echo "Having all peers join the channel..."
#joinChannel

## Set the anchor peers for each org in the channel
#echo "Updating anchor peers for org1..."
#updateAnchorPeers 0 1
#echo "Updating anchor peers for org2..."
#updateAnchorPeers 0 2

if [ "${WITH_CHAINCODE}" != "no" ]; then

	## Install chaincode on peer0.org1 and peer0.org2
	echo "Installing chaincode on peer0.org1..."
	installChaincode 0 1 $CC_NAME
	echo "Install chaincode on peer0.org2..."
	installChaincode 0 2 $CC_NAME

#	# Instantiate chaincode on peer0.org2
#	echo "Instantiating chaincode on peer0.org2..."
#	instantiateChaincode 0 2 $CC_NAME
#
#	# Query chaincode on peer0.org1
#	echo "Querying chaincode on peer0.org1..."
#	chaincodeQuery 0 1 100 $CC_NAME
#
#	# Invoke chaincode on peer0.org1 and peer0.org2
#	echo "Sending invoke transaction on peer0.org1 peer0.org2..."
#	chaincodeInvoke $CC_NAME 0 1 0 2
#	
#	## Install chaincode on peer1.org2
#	echo "Installing chaincode on peer1.org2..."
#	installChaincode 1 2 $CC_NAME
#
#	# Query on chaincode on peer1.org2, check if the result is 90
#	echo "Querying chaincode on peer1.org2..."
#	chaincodeQuery 1 2 90 $CC_NAME
	
fi

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
