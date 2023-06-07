// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import the LP Token
import "./LToken.sol";

// Main contract: UniswapV2-like
contract UniswapAMM {
    // define several public variables
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public fee = 25; // 25 bps = 0.25%
    uint256 public fee0;
    uint256 public fee1;
    address public lt_token;

    // to do floating point arithmetics on the price, we add this scale factor
    uint256 private price_scale_factor = 100000;
    
    // Fire several events
    event LiquidityAdded(address indexed user, uint256 amount0, uint256 amount1);
    event LiquidityRemoved(address indexed user, uint256 amount0, uint256 amount1);
    event Token0Bought(address indexed user, uint256 amount0, uint256 amount1);
    event Token1Bought(address indexed user, uint256 amount0, uint256 amount1);

    // constructor accept 2 arguments: the address of the 2 tokens of the pool
    constructor(address _token0, address _token1) {
        fee0 = 0;
        fee1 = 0;
        token0 = _token0;
        token1 = _token1;
        // create the LP token
        string memory token0Name = ERC20(token0).name();
        string memory token1Name = ERC20(token1).name();
        string memory token0Symbol = ERC20(token0).symbol();
        string memory token1Symbol = ERC20(token1).symbol();
        bytes memory lt_name = abi.encodePacked(token0Name, token1Name);
        bytes memory lt_symbol = abi.encodePacked(token0Symbol, token1Symbol);
        LiquidityToken lToken = new LiquidityToken(string(lt_name), string(lt_symbol));
        lt_token = address(lToken);
    }
    // function to add liquidity to the pool
    // if no liquidity is present it adds corresponding amount of token0 and token1
    // else if add in proportion to the current price taking the lowest value between token0 and token1
    function addLiquidity(uint256 _amount0, uint256 _amount1) external {
        require(_amount0 != 0 && _amount1 != 0, "Cannot add liquidity with either amount at 0");
        uint256 price01 = getExchangeRate10();
        uint256 amount0;
        uint256 amount1;
        if (price01 != 0) {
            uint256 _tentative_share0 = (_amount0 * 100) / reserve0;
            uint256 _tentative_share1 = (_amount1 * 100) / reserve1;
            if (_tentative_share0 < _tentative_share1) {
                amount0 = _amount0;
                amount1 = (reserve1 * _tentative_share0) / 100;
            } else {
                amount1 = _amount1;
                amount0 = (reserve0 * _tentative_share1) / 100;
            }
        } else {
            amount0 = _amount0;
            amount1 = _amount1;
        }
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        reserve0 += amount0;
        reserve1 += amount1;

        emit LiquidityAdded(msg.sender, amount0, amount1);
        LiquidityToken(lt_token).mint(amount0, msg.sender);
        
    }
    
    // function that removes liquidity from the pool
    // can be called only by LPToken owners
    function removeLiquidity(uint256 _liquidity) external {
        uint256 balance = IERC20(lt_token).balanceOf(msg.sender);
        require(_liquidity <= balance, "User does not have this much LToken");

        uint256 total_supply = IERC20(lt_token).totalSupply();
        uint256 share_of_reserves = _liquidity * price_scale_factor / total_supply;

        uint256 amount0 = share_of_reserves * reserve0 / price_scale_factor;
        uint256 amount1 = share_of_reserves * reserve1 / price_scale_factor;

        uint256 _withdraw_fee0 = share_of_reserves * fee0 / price_scale_factor;
        uint256 _withdraw_fee1 = share_of_reserves * fee1 / price_scale_factor;

        IERC20(token0).transfer(msg.sender, amount0 + _withdraw_fee0);
        IERC20(token1).transfer(msg.sender, amount1 + _withdraw_fee1);

        reserve0 -= amount0;
        reserve1 -= amount1;

        fee0 -= _withdraw_fee0;
        fee1 -= _withdraw_fee1;

        LiquidityToken(lt_token).burn(_liquidity, msg.sender);
        emit LiquidityRemoved(msg.sender, amount0, amount1);
    }
    
    // external function to get the current price of the pool
    function getExchangeRate10() public view returns (uint256) {
        if (reserve0 == 0) {
            return 0;
        }
        return reserve1 * price_scale_factor / reserve0;
    }
    
    // function to buy token0
    function buyToken0(uint256 _amount, uint256 _max_price) external {
        uint256 _amountB;
        uint256 _amountS;
        uint256 _fee;
        (_amountB, _amountS, _fee) = _buyToken(token0, _amount, _max_price);
        reserve0 -= _amountB;
        reserve1 += _amountS;
        fee1 += _fee;
        emit Token0Bought(msg.sender, _amountB, _amountS);
    }

    // function to buy token1
    function buyToken1(uint256 _amount, uint256 _max_price) external {
        uint256 _amountB;
        uint256 _amountS;
        uint256 _fee;
        (_amountB, _amountS, _fee) = _buyToken(token1, _amount, _max_price);
        reserve1 -= _amountB;
        reserve0 += _amountS;
        fee0 += _fee;
        emit Token0Bought(msg.sender, _amountB, _amountS);
    }

    // geenric function to execute the swap
    function _buyToken(address _token, uint256 _amount, uint256 _max_price) internal returns (uint256, uint256, uint256) {
        address tokenB;
        address tokenS;
        uint256 reserveB;
        uint256 reserveS;
        uint256 max_price;
        if (_token == token0) {
            tokenB = token0;
            tokenS = token1;
            reserveB = reserve0;
            reserveS = reserve1;
            max_price = _max_price;
        } else {
            tokenB = token1;
            tokenS = token0;
            reserveB = reserve1;
            reserveS = reserve0;
            max_price = 1 * price_scale_factor**2 / _max_price;
        }

        require(_amount > 0, "Amount of token0 must be greater than 0");
        require(_amount < reserveB, "Not enough reserves to deliver amount");
        
        uint256 max_amountS = (_amount * max_price) / price_scale_factor;

        // pricing rule x * y = k
        uint256 _amountS = (reserveB * reserveS) / (reserveB - _amount) -  reserveS;
        
        require(_amountS <= max_amountS, "max price reached");
    
        uint256 _fee = (_amountS * fee) / 10000; //in unit of token1
        
        require(IERC20(tokenS).balanceOf(msg.sender) >= _amountS + _fee, "Insufficient balance of token1");
        require(IERC20(tokenS).allowance(msg.sender, address(this)) >= _amountS + _fee,
                        "Insufficient allowance of token1");

        IERC20(tokenS).transferFrom(msg.sender, address(this), _amountS + _fee);
        IERC20(tokenB).transfer(msg.sender, _amount);

        return (_amount, _amountS, _fee);
    }
}