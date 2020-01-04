#!/bin/bash

# Import Utils file
. scripts/utils.sh

PEER=$1
ORG=$2
CHANNEL_NAME=$3
VERSION=${4:-1.0}
LANGUAGE=golang


createChannel() {
        setGlobals $PEER $ORG

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

FILE=$CHANNEL_NAME.block

# if genesis block exists don't create it again, just join the peer
if test -f "$FILE"; then
    echo "genesis block exists"
    echo "Joining peer: $PEER of org: $ORG in channel: $CHANNEL_NAME"
    joinChannelWithRetry $PEER $ORG 
    echo "===================== peer$PEER.org$ORG joined channel '$CHANNEL_NAME' ===================== "
    # This need to be checked for updating Anchor Peers
    #updateAnchorPeers $PEER $ORG
    #echo "Updating anchor peers for org$ORG..."

else
    echo "Creating Channel with name: $CHANNEL_NAME"
    echo "for peer: $PEER and org: $ORG"
    createChannel
    echo "Joining peer: $PEER of org: $ORG in channel: $CHANNEL_NAME"
    joinChannelWithRetry $PEER $ORG 
    echo "===================== peer$PEER.org$ORG joined channel '$CHANNEL_NAME' ===================== "
    # This need to be checked for updating Anchor Peers
    #updateAnchorPeers $PEER $ORG
    #echo "Updating anchor peers for org$ORG..."
fi

