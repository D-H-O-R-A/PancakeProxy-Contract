// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUniversalRouter {
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view returns (bytes4);
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4);
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4);
    
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function stableSwapFactory() external view returns (address);
    function stableSwapInfo() external view returns (bytes memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function collectRewards(bytes32[] calldata rewardIds) external payable;
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external payable;
    function pause() external;
    function renounceOwnership() external;
    function setStableSwap(bytes calldata swapInfo) external;
    function transferOwnership(address newOwner) external;
    function unpause() external;
}

contract PancakeUniversalRouterProxy {
    address private immutable universalRouter;
    address private _admin;
    uint16 private _feeRate;
    
    error NotAdmin();
    error InvalidAddress();
    error FeeTooHigh();
    error CallFailed(bytes reason);
    
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

    // ============ Funções de Leitura ============
    function admin() external view returns (address) {
        return _admin;
    }

    function feeRate() external view returns (uint16) {
        return _feeRate;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(
            abi.encodeCall(
                IUniversalRouter.onERC1155BatchReceived,
                (operator, from, ids, values, data)
            )
        );
        if (!success) revert CallFailed(result);
        return abi.decode(result, (bytes4));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(
            abi.encodeCall(
                IUniversalRouter.onERC1155Received,
                (operator, from, id, value, data)
            )
        );
        if (!success) revert CallFailed(result);
        return abi.decode(result, (bytes4));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(
            abi.encodeCall(
                IUniversalRouter.onERC721Received,
                (operator, from, tokenId, data)
            )
        );
        if (!success) revert CallFailed(result);
        return abi.decode(result, (bytes4));
    }

    function owner() external view returns (address) {
        return IUniversalRouter(universalRouter).owner();
    }

    function paused() external view returns (bool) {
        return IUniversalRouter(universalRouter).paused();
    }

    function stableSwapFactory() external view returns (address) {
        return IUniversalRouter(universalRouter).stableSwapFactory();
    }

    function stableSwapInfo() external view returns (bytes memory) {
        return IUniversalRouter(universalRouter).stableSwapInfo();
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return IUniversalRouter(universalRouter).supportsInterface(interfaceId);
    }

    // ============ Funções de Escrita ============
    function _applyFee() internal returns (uint256 operationValue) {
        uint256 totalValue = msg.value;
        uint256 fee = (totalValue * _feeRate) / 10000;
        operationValue = totalValue - fee;
        
        if (fee > 0) {
            payable(_admin).transfer(fee);
            emit FeeCollected(_admin, fee);
        }
    }

    function collectRewards(bytes32[] calldata rewardIds) external payable {
        uint256 operationValue = _applyFee();
        IUniversalRouter(universalRouter).collectRewards{value: operationValue}(rewardIds);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs) external payable {
        uint256 operationValue = _applyFee();
        IUniversalRouter(universalRouter).execute{value: operationValue}(commands, inputs);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable {
        uint256 operationValue = _applyFee();
        (bool success, bytes memory result) = universalRouter.call{value: operationValue}(
            abi.encodeCall(
                IUniversalRouter.execute,
                (commands, inputs, deadline)
            )
        );
        if (!success) revert CallFailed(result);
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external payable {
        uint256 operationValue = _applyFee();
        (bool success, bytes memory result) = universalRouter.call{value: operationValue}(
            abi.encodeCall(
                IUniversalRouter.pancakeV3SwapCallback,
                (amount0Delta, amount1Delta, data)
            )
        );
        if (!success) revert CallFailed(result);
    }

    function pause() external {
        IUniversalRouter(universalRouter).pause();
    }

    function renounceOwnership() external {
        IUniversalRouter(universalRouter).renounceOwnership();
    }

    function setStableSwap(bytes calldata swapInfo) external {
        IUniversalRouter(universalRouter).setStableSwap(swapInfo);
    }

    function transferOwnership(address newOwner) external {
        IUniversalRouter(universalRouter).transferOwnership(newOwner);
    }

    function unpause() external {
        IUniversalRouter(universalRouter).unpause();
    }

    // ============ Funções Admin ============
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAddress();
        _admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    function setFeeRate(uint16 newRate) external onlyAdmin {
        if (newRate > 2000) revert FeeTooHigh();
        _feeRate = newRate;
        emit FeeRateUpdated(newRate);
    }

    receive() external payable {}
}
