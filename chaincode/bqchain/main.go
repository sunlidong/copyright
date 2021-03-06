package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
	"strconv"
)

type RightChaincode struct {
}

type Right struct {
	Name      string `json:"name"`
	Author    string `json:"author"`
	Press     string `json:"press"`
	Timestamp int64  `json:"timestamp"`
	Hash      string `json:"hash"`
	Signature string `json:"signature"`
	IDnumber  string `json:"IDnumber"`
}

func main() {
	err := shim.Start(new(RightChaincode))
	if err != nil {
		fmt.Printf("Error starting install chaincode: %s", err)
	}
}

func (rc *RightChaincode) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (rc *RightChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	fn, args := stub.GetFunctionAndParameters()
	fmt.Println("ChainCode is running" + fn)
	switch fn {
	case "regist":
		if len(args) != 7 {
			return shim.Error("There must be 7 parameters")
		}
		_, err := strconv.ParseInt(args[3], 10, 64)
		if err != nil {
			return shim.Error(args[3] + "Input Timestamp Error!")
		}
		ts, err := stub.GetTxTimestamp()
		if err != nil {
			return shim.Error("Get TimeStamp Error" + err.Error())
		}
		right := &Right{args[0], args[1], args[2], ts.Seconds, args[4], args[5], args[6]}
		return rc.regist(stub, right)
	case "queryRightByName":
		if len(args) != 3 {
			return shim.Error("There must be 3 parameters")
		}
		name := args[0]
		author := args[1]
		press := args[2]
		right, err := rc.queryRightByName(stub, name, author, press)
		if err != nil {
			return shim.Error(err.Error())
		}
		return shim.Success([]byte(right))

	case "InvokeChain":
		return shim.Success([]byte("ok"))
	default:
		return shim.Error("Unsupported function")
	}
}

func (rc *RightChaincode) regist(stub shim.ChaincodeStubInterface, right *Right) peer.Response {
	indexName := "name~author~press"

	indexKey, err := stub.CreateCompositeKey(indexName, []string{right.Name, right.Author, right.Press})
	if err != nil {
		return shim.Error(err.Error())
	}

	bytesValue, err := json.Marshal(right)
	if err != nil {
		return shim.Error("Get json Error" + err.Error())
	}

	stub.PutState(indexKey, bytesValue)
	stub.SetEvent("Regist right!", []byte(indexKey))
	return shim.Success([]byte(stub.GetTxID()))
}

func (rc *RightChaincode) queryRightByName(stub shim.ChaincodeStubInterface, name string, author string, press string) (string, error) {
	indexName := "name~author~press"
	indexKey, err := stub.CreateCompositeKey(indexName, []string{name, author, press})
	if err != nil {
		return "Failde to createCompositKey", err
	}
	right, err := stub.GetState(indexKey)
	if err != nil {
		return "", fmt.Errorf("Failed to get right: %s with error: %s", name, err)
	}
	if right == nil {
		return "", fmt.Errorf("Asset not found: %s", name)
	}
	return string(right), nil
}
