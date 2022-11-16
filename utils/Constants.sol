// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Vm.sol";

contract Constants {
    mapping(string => address) private addressMap;
    mapping(string => bytes32) private pairCodeHash;
    //byteCodeHash for trident pairs

    string[] private addressKeys;

    constructor() {
        //setAddress("sushiDeployer", )

        // Mainnet
        setAddress("mainnet.bentobox", 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);
        setAddress("mainnet.weth", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        setAddress("mainnet.sushi", 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
        setAddress("mainnet.usdc", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        setAddress("mainnet.usdt", 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        setAddress("mainnet.chainlink.usdc.eth", 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4); // usdc/eth
        setAddress("mainnet.chainlink.sushi.eth", 0xe572CeF69f43c2E488b33924AF04BDacE19079cf); // sushi/eth
        setAddress("mainnet.chainlink.usdc", 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); // usdc/usd
        setAddress("mainnet.oracle.chainlinkV2", 0x00632CFe43d8F9f8E6cD0d39Ffa3D4fa7ec73CFB);
        setAddress("mainnet.whale.sushi", 0xcBE6B83e77cdc011Cc18F6f0Df8444E5783ed982);
        setAddress("mainnet.whale.usdc", 0x55FE002aefF02F77364de339a1292923A15844B8);

        setAddress("mainnet.kashiV1.usdc.sushi", 0x263716dEe5b74C5Baed665Cb19c6017e51296fa2);

        // Optimism


        // Arbitrum


        // Polygon


        // Fantom


        pairCodeHash["mainnet.sushiV2"] = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
        // bytescodehashes for trident pool types
    }

    function initAddressLabels(Vm vm) public {
        for (uint256 i = 0; i < addressKeys.length; i++) {
            string memory key = addressKeys[i];
            vm.label(addressMap[key], key);
        }
    }

    function setAddress(string memory key, address value) public {
        require(addressMap[key] == address(0), string.concat("address already exists: ", key));
        addressMap[key] = value;
        addressKeys.push(key);
    }

    function getAddress(string calldata key) public view returns (address) {
        require(addressMap[key] != address(0), string.concat("address not found: ", key));
        return addressMap[key];
    }

    function getPairCodeHash(string calldata key) public view returns (bytes32) {
        require(pairCodeHash[key] != "", string.concat("pairCodeHash not found: ", key));
        return pairCodeHash[key];
    }



}
