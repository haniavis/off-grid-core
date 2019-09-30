#!/bin/bash


VERBOSE=true


. utils.sh

PEER=$1
ORG=$2

echo "set Globals to Peer$PEER and ORG$ORG"
setGlobals $PEER $ORG

#echo "result: $res"

exit 0
