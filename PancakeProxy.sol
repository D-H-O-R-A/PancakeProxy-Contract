// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPancakeRouterV2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external view returns (address);
    function factory() external view returns (address);
    function getAmountIn(uint amountOut, address[] calldata path) external view returns (uint amountIn);
    function getAmountOut(uint amountIn, address[] calldata path) external view returns (uint amountOut);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amountsIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amountsOut);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

contract PancakeProxy {
    address private _admin;
    IPancakeRouterV2 public immutable pancakeRouter;
    uint8 private _feePercentage = 10;

    error NotAdmin();
    error FeeTooHigh();
    error InvalidAddress();
    error InsufficientETHForFee();
    error FeeTransferFailed();

    event FeeTransferred(address indexed admin, uint amount);

    constructor(address _router) {
        _admin = msg.sender;
        pancakeRouter = IPancakeRouterV2(_router);
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function feePercentage() external view returns (uint8) {
        return _feePercentage;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert NotAdmin();
        _;
    }

    function setFeePercentage(uint8 _newFee) external onlyAdmin {
        if (_newFee > 100) revert FeeTooHigh();
        _feePercentage = _newFee;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert InvalidAddress();
        _admin = _newAdmin;
    }

    receive() external payable {}
    fallback() external payable {}

    function _applyFee(uint ethAmount) internal returns (uint fee) {
        fee = (ethAmount * _feePercentage) / 100;
        if (address(this).balance < fee) revert InsufficientETHForFee();
        (bool sent, ) = _admin.call{value: fee}("");
        if (!sent) revert FeeTransferFailed();
        emit FeeTransferred(_admin, fee);
    }

    // Wrapper functions
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB, liquidity) = pancakeRouter.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        uint fee = _applyFee(msg.value);
        (amountToken, amountETH, liquidity) = pancakeRouter.addLiquidityETH{
            value: msg.value - fee
        }(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        (amountA, amountB) = pancakeRouter.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = pancakeRouter.removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH) {
        amountETH = pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = pancakeRouter.removeLiquidityETHWithPermit(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline,
            approveMax,
            v,
            r,
            s
        );
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH) {
        amountETH = pancakeRouter.removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline,
            approveMax,
            v,
            r,
            s
        );
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        uint fee = _applyFee(msg.value);
        amounts = pancakeRouter.swapExactETHForTokens{value: msg.value - fee}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = pancakeRouter.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        uint fee = _applyFee(msg.value);
        amounts = pancakeRouter.swapETHForExactTokens{value: msg.value - fee}(
            amountOut,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = pancakeRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = pancakeRouter.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        uint fee = _applyFee(msg.value);
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value - fee
        }(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = pancakeRouter.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    // View functions
    function WETH() external view returns (address) {
        return pancakeRouter.WETH();
    }

    function factory() external view returns (address) {
        return pancakeRouter.factory();
    }

    function getAmountIn(uint amountOut, address[] calldata path) external view returns (uint amountIn) {
        return pancakeRouter.getAmountIn(amountOut, path);
    }

    function getAmountOut(uint amountIn, address[] calldata path) external view returns (uint amountOut) {
        return pancakeRouter.getAmountOut(amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amountsIn) {
        return pancakeRouter.getAmountsIn(amountOut, path);
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amountsOut) {
        return pancakeRouter.getAmountsOut(amountIn, path);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) external view returns (uint amountB) {
        return pancakeRouter.quote(amountA, reserveA, reserveB);
    }
}
