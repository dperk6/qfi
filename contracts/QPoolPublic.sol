// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract QPoolPublic is ERC20, ERC20Burnable {
    using SafeMath for uint256;

    string public poolName;
    address[] private tokens;
    uint256[] private amounts;
    address public creator;
    address private uniswapFactoryAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    
    address[] private depositors;
    mapping(address => uint) private deposits;
    
    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);
    
    constructor(
        string memory _poolName,
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _creator
        ) ERC20 ("QPoolDepositToken", "QPDT") public {
            uint256 _total = 0;
            for (uint256 i = 0; i < _amounts.length; i++) {
                _total += _amounts[i];
            }
            require(_total == 100);
            poolName = _poolName;
            tokens = _tokens;
            amounts = _amounts;
            creator = _creator;
            uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
        }
    
    fallback() external payable {
        processDeposit();
    }

    receive() external payable {
        processDeposit();
    }

    function processDeposit() public {
        address[] memory _path = new address[](2);
        _path[0] = uniswapRouter.WETH();
        for (uint256 i = 0; i < tokens.length; i++) {
            _path[1] = tokens[i];
            uint256 _time = now + 15 + i;
            uint256 _amountEth = msg.value * amounts[i] / 100;
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = uniswapRouter.swapExactETHForTokens.value(_expected[0])(_expected[1], _path, address(this), _time);
            emit TradeCompleted(_output);
        }
        if (deposits[msg.sender] == 0) addDepositor(msg.sender);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        _mint(msg.sender, msg.value);
        emit DepositProcessed(msg.value);
    }
    
    function addDepositor(address _depositor) internal {
        (bool _isDepositor, ) = isDepositor(_depositor);
        if(!_isDepositor) depositors.push(_depositor);
    }
    
    function removeDepositor(address _depositor) public {
        (bool _isDepositor, uint256 i) = isDepositor(_depositor);
        if (_isDepositor) {
            depositors[i] = depositors[depositors.length - 1];
            depositors.pop();
        }
    }
    
    function isDepositor(address _address) public view returns (bool, uint256) {
        for (uint256 i = 0; i < depositors.length; i++) {
            if (_address == depositors[i]) return (true, i);
        }
        return (false, 0);
    }
        
    function totalDeposits() public view returns (uint256) {
        uint256 _totalDeposits = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            _totalDeposits = _totalDeposits.add(deposits[depositors[i]]);
        }
        return _totalDeposits;
    }
    
    function withdrawEth(uint256 _percent) public {
        require(_percent > 0);
        address[] memory _path = new address[](2);
        uint256 _poolTokenBalance = balanceOf(msg.sender);
        uint256 _burnAmount = _poolTokenBalance * _percent / 100;
        uint256 _poolShare = 100 * deposits[msg.sender] / totalDeposits();
        require(approve(address(this), _burnAmount));
        _burn(msg.sender, _burnAmount);
        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance * _poolShare * _percent / 10000;
            require(_amountOut > 0);
            require(_token.approve(address(uniswapRouter), _amountOut));
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000);
            uint256 _time = now + 15 + i;
            uint256[] memory _output = uniswapRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, msg.sender, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        deposits[msg.sender] = deposits[msg.sender] - _burnAmount;
        if (deposits[msg.sender] == 0) removeDepositor(msg.sender);
        emit WithdrawalProcessed(total);
    }
    
    function withdrawTokens() public {
        uint256 _poolTokenBalance = balanceOf(msg.sender);
        uint256 _poolShare = 100 * deposits[msg.sender] / totalDeposits();
        require(approve(address(this), _poolTokenBalance));
        _burn(msg.sender, _poolTokenBalance);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _tokenBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _tokenBalance * _poolShare / 100;
            _token.transfer(msg.sender, _amountOut);
        }
        deposits[msg.sender] = deposits[msg.sender] - _poolTokenBalance;
        removeDepositor(msg.sender);
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getAmounts() public view returns (uint[] memory) {
        return amounts;
    }
}