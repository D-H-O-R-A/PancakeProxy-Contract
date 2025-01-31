// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUniversalRouter {
    function onERC1155BatchReceived(address,address,uint256[] calldata,uint256[] calldata,bytes calldata) external view returns (bytes4);
    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external view returns (bytes4);
    function onERC721Received(address,address,uint256,bytes calldata) external view returns (bytes4);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function stableSwapFactory() external view returns (address);
    function stableSwapInfo() external view returns (bytes memory);
    function supportsInterface(bytes4) external view returns (bool);
    function collectRewards(bytes32[] calldata) external payable;
    function execute(bytes calldata,bytes[] calldata) external payable;
    function execute(bytes calldata,bytes[] calldata,uint256) external payable;
    function pancakeV3SwapCallback(int256,int256,bytes calldata) external payable;
    function pause() external;
    function renounceOwnership() external;
    function setStableSwap(bytes calldata) external;
    function transferOwnership(address) external;
    function unpause() external;
}

interface IUniversalRouterExecute {
    function execute(bytes calldata,bytes[] calldata,uint256) external payable;
}

contract PancakeUniversalRouterProxy {
    address public immutable universalRouter;
    address private _admin;
    uint16 private _feeRate;

    error NotAdmin();
    error InvalidAddress();
    error FeeTooHigh();
    error CallFailed(bytes);
    
    event FeeCollected(address indexed admin, uint256 amount);
    event AdminUpdated(address indexed newAdmin);
    event FeeRateUpdated(uint16 newRate);

    constructor(address router_, address admin_) {
        universalRouter = router_;
        _admin = admin_;
        _feeRate = 1000;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert NotAdmin();
        _;
    }

    // Funções de Leitura Otimizadas
    function admin() external view returns (address) { return _admin; }
    function feeRate() external view returns (uint16) { return _feeRate; }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool s, bytes memory r) = universalRouter.staticcall(
            abi.encodeCall(IUniversalRouter.onERC1155BatchReceived, (operator, from, ids, values, data))
        );
        if (!s) revert CallFailed(r);
        return abi.decode(r, (bytes4));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool s, bytes memory r) = universalRouter.staticcall(
            abi.encodeCall(IUniversalRouter.onERC1155Received, (operator, from, id, value, data))
        );
        if (!s) revert CallFailed(r);
        return abi.decode(r, (bytes4));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool s, bytes memory r) = universalRouter.staticcall(
            abi.encodeCall(IUniversalRouter.onERC721Received, (operator, from, tokenId, data))
        );
        if (!s) revert CallFailed(r);
        return abi.decode(r, (bytes4));
    }

    function owner() external view returns (address) { return IUniversalRouter(universalRouter).owner(); }
    function paused() external view returns (bool) { return IUniversalRouter(universalRouter).paused(); }
    function stableSwapFactory() external view returns (address) { return IUniversalRouter(universalRouter).stableSwapFactory(); }
    function stableSwapInfo() external view returns (bytes memory) { return IUniversalRouter(universalRouter).stableSwapInfo(); }
    function supportsInterface(bytes4 i) external view returns (bool) { return IUniversalRouter(universalRouter).supportsInterface(i); }

    // Funções de Escrita Ultra-Otimizadas
    function _applyFee() internal returns (uint256 o) {
        uint256 t = msg.value;
        uint256 f = (t * _feeRate) / 10000;
        o = t - f;
        if (f > 0) {
            payable(_admin).transfer(f);
            emit FeeCollected(_admin, f);
        }
    }

    function collectRewards(bytes32[] calldata r) external payable {
        IUniversalRouter(universalRouter).collectRewards{value: _applyFee()}(r);
    }

    function execute(bytes calldata c, bytes[] calldata i) external payable {
        IUniversalRouter(universalRouter).execute{value: _applyFee()}(c, i);
    }

    function execute(bytes calldata c, bytes[] calldata i, uint256 d) external payable {
        (bool s, bytes memory r) = universalRouter.call{value: _applyFee()}(
            abi.encodeCall(IUniversalRouterExecute.execute, (c, i, d))
        );
        if (!s) revert CallFailed(r);
    }

    function pancakeV3SwapCallback(int256 a0, int256 a1, bytes calldata d) external payable {
        (bool s, bytes memory r) = universalRouter.call{value: _applyFee()}(
            abi.encodeCall(IUniversalRouter.pancakeV3SwapCallback, (a0, a1, d))
        );
        if (!s) revert CallFailed(r);
    }

    // Funções Admin Otimizadas
    function setAdmin(address a) external onlyAdmin {
        if (a == address(0)) revert InvalidAddress();
        _admin = a;
        emit AdminUpdated(a);
    }

    function setFeeRate(uint16 r) external onlyAdmin {
        if (r > 2000) revert FeeTooHigh();
        _feeRate = r;
        emit FeeRateUpdated(r);
    }

    // Funções sem taxa com chamada direta
    function pause() external { IUniversalRouter(universalRouter).pause(); }
    function renounceOwnership() external { IUniversalRouter(universalRouter).renounceOwnership(); }
    function setStableSwap(bytes calldata s) external { IUniversalRouter(universalRouter).setStableSwap(s); }
    function transferOwnership(address o) external { IUniversalRouter(universalRouter).transferOwnership(o); }
    function unpause() external { IUniversalRouter(universalRouter).unpause(); }

    receive() external payable {}
}
