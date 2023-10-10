// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "lib/forge-std/src/Test.sol";

abstract contract Helpers is Test {

    function makeaddr(
        string memory name 
    ) public returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    function switchSigner(
        address _newSigner
    ) public {
        vm.startPrank(_newSigner);
        vm.deal(_newSigner, 5 ether);
        vm.label(_newSigner, "USER");
    }
}