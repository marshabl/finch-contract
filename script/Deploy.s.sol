// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Script.sol";

interface ICockroach {
    function recoverERC20(address token) external;
    function recoverETH() external;
    function transferERC20(address token, uint256 amountIn, address to) external;
    function swapERC20(address token, uint256 amount0, uint256 amount1) external;
    function arb(bytes memory data) external;
}



contract Deploy is Script {

  address constant USER = address(0x95770a669A5483696694C4c4BE7493137B4B5b1e);

  function run() public returns (ICockroach roach) {
    vm.startBroadcast();
    roach = ICockroach(HuffDeployer
      .config()
      .with_addr_constant("USER", USER)
      .deploy("SimpleStore")
    );

    // ICockroach roach = ICockroach(addr);
    vm.stopBroadcast();

  }
}
