// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract QFinanceToken is ERC20, ERC20Burnable, ERC20Capped {
    using SafeMath for uint256;
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    address public factory;
} 