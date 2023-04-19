// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WETH9.sol";

contract WETH9Test is Test {
    WETH9 public weth9;

    receive() external payable {}

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function setUp() public {
        weth9 = new WETH9();
    }

    // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
    function test1() public {
        weth9.deposit{value: 1}();
        assertEq(weth9.balanceOf(address(this)), 1);
    }

    // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
    function test2() public {
        weth9.deposit{value: 1}();
        assertEq(address(weth9).balance, 1);
    }

    // 測項 3: deposit 應該要 emit Deposit event
    function test3() public {
        vm.expectEmit();
        emit Deposit(address(this), 1);
        weth9.deposit{value: 1}();
    }

    // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
    function test4(uint96 wad) public {
        weth9.deposit{value: wad}();
        uint256 preBalance = weth9.totalSupply();
        weth9.withdraw(wad);
        uint256 postBalance = weth9.totalSupply();
        assertEq(preBalance - wad, postBalance);
    }

    // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
    function test5(uint96 wad) public {
        weth9.deposit{value: wad}();
        uint256 preBalance = address(this).balance;
        weth9.withdraw(wad);
        uint256 postBalance = address(this).balance;
        assertEq(preBalance + wad, postBalance);
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
        weth9.transfer(address(123), 10);
        assertEq(weth9.balanceOf(address(this)), 10);
        assertEq(weth9.balanceOf(address(123)), 10);
    }

    // 測項 8: approve 應該要給他人 allowance
    function test8(uint96 wad) public {
        weth9.approve(address(123), wad);
        assertEq(weth9.allowance(address(this),address(123)), wad);
    }

    // 測項 9: transferFrom 應該要可以使用他人的 allowance
    function test9() public {
        weth9.deposit{value: 20}();
        weth9.approve(address(123), 10);
        vm.startPrank(address(123));
        bool result = weth9.transferFrom(address(this), address(456), 5);
        assertEq(result, true);
    }

    // 測項 10: transferFrom 後應該要減除用完的 allowance
    function test10() public {
        weth9.deposit{value: 20}();
        weth9.approve(address(123), 10);
        vm.startPrank(address(123));
        weth9.transferFrom(address(this), address(456), 5);
        assertEq(weth9.allowance(address(this),address(123)), 5);
    }

    // 其他可以 test case 可以自己想，看完整程度給分
}
