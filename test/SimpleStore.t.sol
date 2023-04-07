// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import { IWETH } from "../interfaces/IWETH.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import {
    IUniswapV2Router02,
    IUniswapV2Factory,
    IUniswapV2Pair
} from "../interfaces/IUniswapV2.sol";

interface ICockroach {
}

address constant USER = address(); //add your EOA

contract SimpleStoreTest is Test {
    ICockroach public roach;

    // IWETH weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    // IERC20 uni = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    // IUniswapV2Router02 uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // IUniswapV2Router02 sushiV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    // IUniswapV2Pair wethUniUni;
    // IUniswapV2Pair wethUniSushi;

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 fab = IERC20(0x8EE325AE3E54e83956eF2d5952d3C8Bc1fa6ec27);
    IERC20 inv = IERC20(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68);

    IUniswapV2Pair wethFabUni;
    IUniswapV2Pair wethFabSushi;
    IUniswapV2Pair wethInvUni;
    

    IUniswapV2Router02 uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory univ2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 sushiV2Router = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Factory sushiv2Factory = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    

    /// @dev Setup the testing environment.
    function setUp() public {
        weth.deposit{value: 1000e18}();

        // wethUniUni = IUniswapV2Pair(address(0x28cee28a7C4b4022AC92685C07d2f33Ab1A0e122));
        // wethUniSushi = IUniswapV2Pair(address(0x6D2fAf643Fe564e0204f35e38d1a1b08D9620d14));

        wethFabUni = IUniswapV2Pair(univ2Factory.getPair(address(weth), address(fab)));
        wethFabSushi = IUniswapV2Pair(sushiv2Factory.getPair(address(weth), address(fab)));
        // wethInvUni = IUniswapV2Pair(univ2Factory.getPair(address(weth), address(inv)));

        roach = ICockroach(HuffDeployer
            .config()
            .with_addr_constant("USER", USER)
            .deploy("SimpleStore")
        );

        weth.transfer(address(roach), 1000e18);
    }

    // function testRecoverWETH() public {
    //     bytes memory payload = getMultiPayload();
    //     vm.startPrank(USER);
    //     console.log(weth.balanceOf(address(roach)));
    //     (bool u, ) = address(roach).call(payload);
    //     console.log(weth.balanceOf(address(roach)));
    //     vm.stopPrank();

    //     // assertEq(weth.balanceOf(address(roach)), 1);
    //     // assertEq(weth.balanceOf(USER), 10e18 - 1);
    // }

    function testArb() public {
        vm.startPrank(USER);
        bytes memory payload = getMultiPayload();

        console.log(weth.balanceOf(address(roach)));
        uint256 _before = gasleft();
        (bool u, ) = address(roach).call(payload);
        uint256 _after = gasleft();
        console.log(weth.balanceOf(address(roach)));
        
        console2.log("Gas used: ", (_before - _after));

        vm.stopPrank();
    }

    /// @notice Constructs a sandwich payload
    function getSwapBytes(IUniswapV2Router02 router, address next, address token0, address token1, uint256 amountIn) internal view returns (bytes memory payload, uint256 out) {
        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        out = router.getAmountsOut(amountIn, path)[1] - 1;
        uint112 amountOut = uint112(out);
        uint8 dir = address(token0) > address(token1) ? 0 : 1;
        console.log(dir);

        if (next == address(0)) {
            payload = abi.encodePacked(
                amountOut,
                dir
            ); 
        } else {
            payload = abi.encodePacked(
                next,
                amountOut,
                dir
            );  
        }
    }

    /// @notice Constructs a sandwich payload
    function getMultiPayload() internal view returns (bytes memory payload) {
        uint256 amountIn0 = 10696379953659087;

        bytes memory a = abi.encodePacked(
            uint8(0),
            uint8(2),
            uint112(amountIn0),
            address(wethFabSushi)
        );
        
        (bytes memory b, uint256 amountOut0) = getSwapBytes(
            uniV2Router,
            address(wethFabUni),
            address(weth),
            address(fab),
            amountIn0
        );

        (bytes memory c, uint256 amountOut1) = getSwapBytes(
            sushiV2Router,
            address(0),
            address(fab),
            address(weth),
            amountOut0
        );

        // (bytes memory d, uint256 amountOut2) = getSwapBytes(
        //     sushiV2Router,
        //     address(wethUsdcSushi),
        //     address(mask),
        //     address(usdc),
        //     amountOut1
        // );

        // (bytes memory e, uint256 amountOut3) = getSwapBytes(
        //     uniV2Router,
        //     address(0),
        //     address(inv),
        //     address(weth),
        //     amountOut1
        // );

        

        payload = bytes.concat(a, b, c);
        console.logBytes(payload);
        
    }
    

    // /// @notice Constructs a sandwich payload
    // function getMultiPayload() internal view returns (bytes memory payload) {

    //     //numSwaps | type of swaps | WETH or USDC | amountIn | pair0, pair1, etc | 0or1 + amountOut0, 0or1 + amountOut1, etc
    //     uint256 amountIn0 = 1e16;

    //     bytes memory a = abi.encodePacked(
    //         uint8(0),
    //         uint8(2),
    //         uint112(amountIn0),
    //         address(wethUniUni)
    //     );
        
    //     (bytes memory b, uint256 amountOut0) = getSwapBytes(
    //         uniV2Router,
    //         address(wethUniSushi),
    //         address(weth),
    //         address(uni),
    //         amountIn0
    //     );

    //     (bytes memory c, uint256 amountOut1) = getSwapBytes(
    //         sushiV2Router,
    //         address(0),
    //         address(uni),
    //         address(weth),
    //         amountOut0
    //     );

    //     payload = bytes.concat(a, b, c);
    //     console.logBytes(payload);
    // }
}


