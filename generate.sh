#!/usr/bin/env bash
##
## Copyright IBM Corp All Rights Reserved
##
## SPDX-License-Identifier: Apache-2.0
##

CHANNEL_NAME="assetpublish"

sleep 1

# generate genesis block for orderer
configtxgen -profile SampleMultiNodeEtcdRaft   -outputBlock  ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for ProductOrg..."
  exit 1
fi

# generate anchor peer transaction two
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./config/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for FactoringOrg..."
  exit 1
fi
