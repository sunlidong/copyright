#!/usr/bin/env bash


#!/usr/bin/env bash
SLEEP_SECOND=5
SLEEP_SECOND2=5
SLEEP_SECOND1=20




###  需要修改参数
GO_CC_NAME=("AssetToChain_realty" "AssetToChain_increment")
GO_CC_SRC_PATH=("github.com/chaincode/chaincodeRealty/dingchain"  "github.com/chaincode/chaincodeRealty/increment")
CC_VERSION="1.0"



### 参数
CHANNEL_NAME="channelcopyright"
DOMAIN_NAME="bqchain.com"
ORDERER0_ADDRESS="orderer0.bqchain.com:7050"
#GO_CC_NAME=("AssetToChain" "IncrementChaincode")
#GO_CC_SRC_PATH=("github.com/chaincode/dingchain"  "github.com/chaincode/increment")
ORG_NAME=("org1" "org2")
CC_VERSION="1.0"
TLS_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-channel-artifacts/"
ORDERER_TLS_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-channel-artifacts/"
ORDERER_CAFILE= "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/bqchain.com/orderers/orderer1.bqchain.com/msp/tlscacerts/tlsca.bqchain.com-cert.pem"
### 开始
echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your DRC Server......."
echo
###

###
get_mspid() {
    local org=$1
    case "$org" in
        org1)
            echo "Org1MSP"
            ;;
        org2)
            echo "Org2MSP"
            ;;
        *)
            echo "error org name $org"
            exit 1
            ;;
    esac
}

get_msp_channel-artifacts_path() {

    local org=$1
    local peer=$2

    if [[ "$org" = "Org1" ]] && [[ "$org" = "Org2" ]]; then
        echo "error org name $org"
        exit 1
    fi

    if [[ "$peer" = "peer0" ]] && [[ "$peer" = "peer1" ]]; then
        echo "error peer name $peer"
        exit 1
    fi

    echo "${TLS_PATH}peerOrganizations/$org.bqchain.com/users/Admin@$org.bqchain.com/msp"

}

get_peer_address() {
    local org=$1
    local peer=$2
    local port=$3
    if [[ "$org" != "org1" ]] && [[ "$org" != "org2" ]]; then
        echo "error org name $org"
        exit 1
    fi

    echo "${peer}.${org}.${DOMAIN_NAME}:$port"
}

get_peer_tls_cert(){
    local org=$1
    local peer=$2
    local type=$3
    if [[ "$org" != "org1" ]] && [[ "$org" != "org2" ]]; then
        echo "error org name $org"
        exit 1
    fi

    echo "${TLS_PATH}peerOrganizations/${org}.bqchain.com/peers/${peer}.${org}.bqchain.com/tls/$type"

}

get_orderer_tls_cert(){
    local org=$1
    if [[ "$org" != "orderer0" ]] && [[ "$org" != "orderer1" ]]; then
        echo "error org name $org"
        exit 1
    fi

    echo "${ORDERER_TLS_PATH}ordererOrganizations/bqchain.com/orderers/orderer0.bqchain.com/tls/tlsintermediatecerts/tls-localhost-7055.pem"
}

### 第一步：创建通道
channel_create() {
    local channel=$1
    local org="org1"
    local peer="peer0"
    local port="7051"
    local cert="server.crt"
    local key="server.key"
    local rootcert="ca.crt"
    local orderer="orderer1"

    docker exec \
        -e "CORE_PEER_LOCALMSPID=Org1MSP" \
        -e "CORE_PEER_MSPchannel-artifactsPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.bqchain.com/users/Admin@org1.bqchain.com/msp" \
        -e "CORE_PEER_ADDRESS=peer0.org1.bqchain.com:7051" \
        -e "CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.bqchain.com/peers/peer0.org1.bqchain.com/tls/server.crt" \
        -e "CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.bqchain.com/peers/peer0.org1.bqchain.com/tls/server.key" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.bqchain.com/peers/peer0.org1.bqchain.com/tls/ca.crt" \
        cli \
        peer channel create \
                    -o $ORDERER0_ADDRESS \
                    -c $channel \
                    -f ./channel-artifacts/channelcopyright.tx \
                    --tls true \
                    --cafile $ORDERER_CAFILE
}

###
channel_join() {
    local channel=$1
    local org=$2
    local peer=$3
    local port=$4
    local cert=$5
    local key=$6
    local rootcert=$7
    ###
    docker exec \
        -e "CORE_PEER_LOCALMSPID=$(get_mspid $org)"\
        -e "CORE_PEER_MSPchannel-artifactsPATH=$(get_msp_channel-artifacts_path $org $peer)"\
        -e "CORE_PEER_ADDRESS=$(get_peer_address $org $peer $port)"\
        -e "CORE_PEER_TLS_CERT_FILE=$(get_peer_tls_cert $org $peer $cert)"\
        -e "CORE_PEER_TLS_KEY_FILE=$(get_peer_tls_cert $org $peer $key)"\
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$(get_peer_tls_cert $org $peer $rootcert)"\
        cli \
        peer channel \
        join -b $channel.block

     echo "********************$org...$peer join channel successful***************"
}

###
install_and_instantiate_all() {
    local lang=$1
    local cc_name=($2)
    local cc_src_path=($3)

    chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang \
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer1" \
                      "8051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang\
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer0" \
                      "9051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang \
                      "org2"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer1" \
                      "6051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang\
                      "org2"
     ###
     chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      ${cc_src_path[1]} \
                      $lang \
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer1" \
                      "8051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      ${cc_src_path[1]} \
                      $lang\
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer0" \
                      "9051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      ${cc_src_path[1]} \
                      $lang \
                      "org2"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer1" \
                      "6051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      ${cc_src_path[1]} \
                      $lang\
                      "org2"
     ###

    chaincode_instantiate   $CHANNEL_NAME \
							"org1" \
							"peer0" \
							"7051" \
							"server.crt" \
							"server.key" \
							"ca.crt" \
							"orderer0" \
							${cc_name[0]} \
							${cc_src_path[0]} \
							$lang\
							"org1"
	###
	  chaincode_instantiate  $CHANNEL_NAME \
							"org1" \
							"peer0" \
							"7051" \
							"server.crt" \
							"server.key" \
							"ca.crt" \
							"orderer0" \
							${cc_name[1]} \
							${cc_src_path[1]} \
							$lang\
							"org1"
#
##
sleep $SLEEP_SECOND1
#
     chaincode_invoke $CHANNEL_NAME \
                      "org1" \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      "org2" \
                      "org2" \
                      "peer0" \
                      "9051" \
                      '{"function":"","Args":[""]}'
     ###
     chaincode_invoke $CHANNEL_NAME \
                      "org1" \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      "org2" \
                      "org2" \
                      "peer0" \
                      "9051" \
                      '{"function":"","Args":[""]}'
}

install_and_instantiate_one() {
    local lang=$1
    local cc_name=($2)
    local cc_src_path=($3)

    chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang \
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org1" \
                      "peer1" \
                      "8051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang\
                      "org1"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer0" \
                      "9051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang \
                      "org2"

    chaincode_install $CHANNEL_NAME \
                      "org2" \
                      "peer1" \
                      "6051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      ${cc_src_path[0]} \
                      $lang\
                      "org2"



    chaincode_instantiate   $CHANNEL_NAME \
							"org1" \
							"peer0" \
							"7051" \
							"server.crt" \
							"server.key" \
							"ca.crt" \
							"orderer0" \
							${cc_name[0]} \
							${cc_src_path[0]} \
							$lang\
							"org1"
	###
	  chaincode_instantiate  $CHANNEL_NAME \
							"org1" \
							"peer0" \
							"7051" \
							"server.crt" \
							"server.key" \
							"ca.crt" \
							"orderer0" \
							${cc_name[1]} \
							${cc_src_path[1]} \
							$lang\
							"org1"
#
##
sleep $SLEEP_SECOND1
#
     chaincode_invoke $CHANNEL_NAME \
                      "org1" \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[0]} \
                      "org2" \
                      "org2" \
                      "peer0" \
                      "9051" \
                      '{"function":"","Args":[""]}'
     ###
     chaincode_invoke $CHANNEL_NAME \
                      "org1" \
                      "org1" \
                      "peer0" \
                      "7051" \
                      "server.crt" \
                      "server.key" \
                      "ca.crt" \
                      "orderer0" \
                      ${cc_name[1]} \
                      "org2" \
                      "org2" \
                      "peer0" \
                      "9051" \
                      '{"function":"","Args":[""]}'
}

###
chaincode_install() {
    local channel=$1
    local org=$2
    local peer=$3
    local port=$4
    local cert=$5
    local key=$6
    local rootcert=$7
    local orderer=$8
    local cc_name=$9
    local cc_src_path=${10}
    local lang=${11}
    local Org=${12}


    docker exec \
        -e "CORE_PEER_LOCALMSPID=$(get_mspid $org)" \
        -e "CORE_PEER_MSPchannel-artifactsPATH=$(get_msp_channel-artifacts_path $org $peer)" \
        -e "CORE_PEER_ADDRESS=$(get_peer_address $org $peer $port)" \
        -e "CORE_PEER_TLS_CERT_FILE=$(get_peer_tls_cert $org $peer $cert)" \
        -e "CORE_PEER_TLS_KEY_FILE=$(get_peer_tls_cert $org $peer $key)" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$(get_peer_tls_cert $org $peer $rootcert)" \
        cli \
        peer chaincode install \
        -n $cc_name \
        -v $CC_VERSION \
        -l $lang \
        -p $cc_src_path
}

###
chaincode_instantiate() {
    local channel=$1
    local org=$2
    local peer=$3
    local port=$4
    local cert=$5
    local key=$6
    local rootcert=$7
    local orderer=$8
    local cc_name=$9
    local cc_src_path=${10}
    local lang=${11}
    local Org=${12}

    docker exec \
        -e "CORE_PEER_LOCALMSPID=$(get_mspid $org)" \
        -e "CORE_PEER_MSPchannel-artifactsPATH=$(get_msp_channel-artifacts_path $org $peer)" \
        -e "CORE_PEER_ADDRESS=$(get_peer_address $org $peer $port)" \
        -e "CORE_PEER_TLS_CERT_FILE=$(get_peer_tls_cert $org $peer $cert)" \
        -e "CORE_PEER_TLS_KEY_FILE=$(get_peer_tls_cert $org $peer $key)" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$(get_peer_tls_cert $org $peer $rootcert)" \
        cli \
        peer chaincode instantiate -o orderer0.bqchain.com:7050 --tls true --cafile $ORDERER_CAFILE -C $CHANNEL_NAME -n $cc_name -l golang -v 1.0 -c '{"Args":[""]}' -P 'AND ('\''Org1MSP.member'\'','\''Org2MSP.member'\'')'
     echo "*******************************init chaincode is successful*********************************"
}

###
chaincode_invoke() {
    local channel=$1
    local org1=$2
    local Org1=$3
    local peer=$4
    local port=$5
    local cert=$6
    local key=$7
    local rootcert=$8
    local orderer=$9
    local cc_name=${10}
    local org2=${11}
    local Org2=${12}
    local Org2peer=${13}
    local Org2port=${14}
    local  cmd=${15}

    docker exec \
        -e "CORE_PEER_LOCALMSPID=$(get_mspid $org1)" \
        -e "CORE_PEER_MSPchannel-artifactsPATH=$(get_msp_channel-artifacts_path $Org1 $peer)" \
        -e "CORE_PEER_ADDRESS=$(get_peer_address $org1 $peer $port)" \
        -e "CORE_PEER_TLS_CERT_FILE=$(get_peer_tls_cert $org1 $peer $cert)" \
        -e "CORE_PEER_TLS_KEY_FILE=$(get_peer_tls_cert $org1 $peer $key)" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$(get_peer_tls_cert $org1 $peer $rootcert)" \
        cli \
peer chaincode invoke -o orderer0.bqchain.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-channel-artifacts/ordererOrganizations/bqchain.com/orderers/orderer0.bqchain.com/tls/ca.crt -C $CHANNEL_NAME -n $cc_name --peerAddresses peer0.org1.bqchain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-channel-artifacts/peerOrganizations/org1.bqchain.com/peers/peer0.org1.bqchain.com/tls/ca.crt --peerAddresses peer0.org2.bqchain.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto-channel-artifacts/peerOrganizations/org2.bqchain.com/peers/peer0.org2.bqchain.com/tls/ca.crt -c '{"Args":[""]}'

    echo "**********************************invoke chaincode*******$cc_name************************************************"
}


## create channel
channel_create $CHANNEL_NAME

# Join peer0.org1.bqchain.com to the channel.
channel_join $CHANNEL_NAME "org1" "peer0" "7051" "server.crt" "server.key" "ca.crt"
  echo "#################################################################"
  echo "### channel_join   is  org1 peer0                             ###"
  echo "#################################################################"
channel_join $CHANNEL_NAME "org1" "peer1" "8051" "server.crt" "server.key" "ca.crt"
  echo "#################################################################"
  echo "### channel_join   is  org1 peer1                             ###"
  echo "#################################################################"
channel_join $CHANNEL_NAME "org2" "peer0" "9051" "server.crt" "server.key" "ca.crt"
  echo "#################################################################"
  echo "### channel_join   is  org2 peer0                             ###"
  echo "#################################################################"
channel_join $CHANNEL_NAME "org2" "peer1" "6051" "server.crt" "server.key" "ca.crt"
  echo "#################################################################"
  echo "### channel_join   is  org2 peer1                             ###"
  echo "#################################################################"

## 安装链码
#install_and_instantiate_one "golang" "${GO_CC_NAME[*]}" "${GO_CC_SRC_PATH[*]}"
echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

