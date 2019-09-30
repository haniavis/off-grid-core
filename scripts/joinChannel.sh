#!/bin/bash

# Import Utils file
. scripts/utils.sh

PEER=$1
ORG=$2
CHANNEL_NAME=$3
VERSION=${4:-1.0}
LANGUAGE=golang


function genArtifactsAgain() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

#  CHANNEL=$1
#  echo "##########################################################"
#  echo "#########  Generating Orderer Genesis block ##############"
#  echo "##########################################################"
#  # Note: For some unknown reason (at least for now) the block file can't be
#  # named orderer.genesis.block or the orderer will fail to launch!
#  echo "CONSENSUS_TYPE="$CONSENSUS_TYPE
#  set -x
#  if [ "$CONSENSUS_TYPE" == "solo" ]; then
#    configtxgen -profile TwoOrgsOrdererGenesis -channelID $SYS_CHANNEL -outputBlock ./genesis.block
#  elif [ "$CONSENSUS_TYPE" == "kafka" ]; then
#    configtxgen -profile SampleDevModeKafka -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block
#  elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
#    configtxgen -profile SampleMultiNodeEtcdRaft -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block
#  else
#    set +x
#    echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
#    exit 1
#  fi
#  res=$?
#  set +x
#  if [ $res -ne 0 ]; then
#    echo "Failed to generate orderer genesis block..."
#    exit 1
#  fi
#  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org2MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate \
    ./Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi
  echo


  echo "Copying new channel artifacts in CLI container"
  docker cp channel.tx cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/
 # docker cp configtx.tx cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/
  echo "Deleting channel artifacts"
  rm channel.tx
}

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

#genArtifactsAgain
echo "Creating Channel with name: $CHANNEL_NAME"
echo "for peer: $PEER and org: $ORG"
createChannel
echo "Joining peer: $PEER of org: $ORG in channel: $CHANNEL_NAME"
joinChannelWithRetry $PEER $ORG 
echo "===================== peer$PEER.org$ORG joined channel '$CHANNEL_NAME' ===================== "

