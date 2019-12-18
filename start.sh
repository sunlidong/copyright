#!/usr/bin/env bash


### 生成证书
cryptogen generate --config=./crypto-config.yaml

### 生成配置文件

configtxgen -profile BqchainMultiNodeEtcdRaft   -outputBlock  ./channel-artifacts/genesis.block


###
