// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WETH9.sol";

contract WETH9Test is Test {
    WETH9 public weth9;
    address testAddr1 = address(123);
    address testAddr2 = address(456);

    receive() external payable {}

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function setUp() public {
        weth9 = new WETH9();
    }

    // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
    function test1(uint96 randomEth) public {
        weth9.deposit{value: randomEth}();
        assertEq(weth9.balanceOf(address(this)), randomEth);
    }

    // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
    function test2(uint96 randomEth) public {
        weth9.deposit{value: randomEth}();
        assertEq(address(weth9).balance, randomEth);
    }

    // 測項 3: deposit 應該要 emit Deposit event
    function test3(uint96 randomEth) public {
        vm.expectEmit();
        emit Deposit(address(this), randomEth);
        weth9.deposit{value: randomEth}();
    }

    // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
    function test4(uint96 randomEth) public {
        weth9.deposit{value: randomEth}();
        uint256 preBalance = weth9.totalSupply();
        weth9.withdraw(randomEth);
        uint256 postBalance = weth9.totalSupply();
        assertEq(preBalance - randomEth, postBalance);
    }

    // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
    function test5() public {
        weth9.deposit{value: 50 ether}();
        uint256 preBalance = address(this).balance;
        weth9.withdraw(10 ether);
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + 10000000000000000000, postBalance);
    }

    // 測項 6: withdraw 應該要 emit Withdraw event
    function test6(uint96 wad) public {
        weth9.deposit{value: wad}();
        vm.expectEmit();
        emit Withdrawal(address(this), wad);
        weth9.withdraw(wad);
    }

    // 測項 7: transfer 應該要將 erc20 token 轉給別人
    function test7() public {
        weth9.deposit{value: 20}();
        weth9.transfer(testAddr1, 10);
        assertEq(weth9.balanceOf(address(this)), 10);
        assertEq(weth9.balanceOf(testAddr1), 10);
    }

    // 測項 8: approve 應該要給他人 allowance
    function test8(uint96 wad) public {
        weth9.approve(testAddr1, wad);
        assertEq(weth9.allowance(address(this), testAddr1), wad);
    }

    // 測項 9: transferFrom 應該要可以使用他人的 allowance
    function test9() public {
        weth9.deposit{value: 20}();
        weth9.approve(testAddr1, 10);
        vm.prank(testAddr1);
        bool result = weth9.transferFrom(address(this), testAddr2, 5);
        require(result, "test failed");
    }

    // 測項 10: transferFrom 後應該要減除用完的 allowance
    function test10() public {
        weth9.deposit{value: 20}();
        weth9.approve(testAddr1, 10);
        vm.prank(testAddr1);
        weth9.transferFrom(address(this), testAddr2, 5);
        assertEq(weth9.allowance(address(this), testAddr1), 10 - 5);
    }

    // 測項 11: 在 address(this) approve testAddr2 額度之前，testAddr2 transferFrom 應該會 revert
    function test11() public {
        
        weth9.deposit{value: 20}();

        vm.prank(testAddr2);
        vm.expectRevert();
        weth9.transferFrom(address(this), testAddr2, 20);
    }
}
