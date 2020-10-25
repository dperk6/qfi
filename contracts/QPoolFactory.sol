// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "./QPool.sol";
import "./QPoolPublic.sol";

contract QPoolFactory {
    address[] private addresses;
    mapping(address => bool) private isPool;

    event PoolCreated(QPool pool);
    event PublicPoolCreated(QPoolPublic pool);

    function getPools() public view returns (address[] memory) {
        return addresses;
    }

    function checkPool(address _poolAddress) public view returns (bool) {
        return isPool[_poolAddress];
    }

    function newPool(address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPool pool = new QPool(_tokens, _amounts, msg.sender);
        emit PoolCreated(pool);
        addresses.push(address(pool));
        isPool[address(pool)] = true;
        return address(pool);
    }

    function newPublicPool(string memory _name, address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPoolPublic pool = new QPoolPublic(_name, _tokens, _amounts, msg.sender);
        emit PublicPoolCreated(pool);
        addresses.push(address(pool));
        isPool[address(pool)] = true;
    }
}
