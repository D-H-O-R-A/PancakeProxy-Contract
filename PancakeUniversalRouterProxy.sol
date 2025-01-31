// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUniversalRouter {
    // Funções de Leitura
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

    // Funções de Escrita
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
    address public universalRouter;
    address public admin;
    uint256 public feeRate; // 1000 = 10%
    
    event FeeCollected(address indexed admin, uint256 amount);
    event AdminUpdated(address newAdmin);
    event FeeRateUpdated(uint256 newRate);

    constructor(address _router, address _admin) {
        universalRouter = _router;
        admin = _admin;
        feeRate = 1000; // 10% inicial
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Acesso negado");
        _;
    }

    // ====================
    // Funções de Leitura
    // ====================
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSelector(
            IUniversalRouter.onERC1155BatchReceived.selector,
            operator, from, ids, values, data
        ));
        require(success, "Chamada falhou");
        return abi.decode(result, (bytes4));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSelector(
            IUniversalRouter.onERC1155Received.selector,
            operator, from, id, value, data
        ));
        require(success, "Chamada falhou");
        return abi.decode(result, (bytes4));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSelector(
            IUniversalRouter.onERC721Received.selector,
            operator, from, tokenId, data
        ));
        require(success, "Chamada falhou");
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

    // ====================
    // Funções de Escrita (com taxa)
    // ====================
    function collectRewards(bytes32[] calldata rewardIds) external payable {
        uint256 totalValue = msg.value;
        uint256 fee = (totalValue * feeRate) / (10000 + feeRate);
        uint256 operationValue = totalValue - fee;
        
        if(fee > 0) {
            payable(admin).transfer(fee);
            emit FeeCollected(admin, fee);
        }
        
        IUniversalRouter(universalRouter).collectRewards{value: operationValue}(rewardIds);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs) external payable {
        uint256 totalValue = msg.value;
        uint256 fee = (totalValue * feeRate) / (10000 + feeRate);
        uint256 operationValue = totalValue - fee;
        
        if(fee > 0) {
            payable(admin).transfer(fee);
            emit FeeCollected(admin, fee);
        }
        
        IUniversalRouter(universalRouter).execute{value: operationValue}(commands, inputs);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable {
        uint256 totalValue = msg.value;
        uint256 fee = (totalValue * feeRate) / (10000 + feeRate);
        uint256 operationValue = totalValue - fee;
        
        if(fee > 0) {
            payable(admin).transfer(fee);
            emit FeeCollected(admin, fee);
        }
        
        (bool success, bytes memory result) = universalRouter.call{value: operationValue}(
            abi.encodeWithSelector(
                bytes4(0x3593564c), // Selector correto para execute com deadline
                commands,
                inputs,
                deadline
            )
        );
        require(success, string(abi.encodePacked("Execute failed: ", result)));
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external payable {
        uint256 totalValue = msg.value;
        uint256 fee = (totalValue * feeRate) / (10000 + feeRate);
        uint256 operationValue = totalValue - fee;
        
        if(fee > 0) {
            payable(admin).transfer(fee);
            emit FeeCollected(admin, fee);
        }
        
        (bool success, bytes memory result) = universalRouter.call{value: operationValue}(
            abi.encodeWithSelector(
                IUniversalRouter.pancakeV3SwapCallback.selector,
                amount0Delta,
                amount1Delta,
                data
            )
        );
        require(success, string(abi.encodePacked("Callback failed: ", result)));
    }

    // ====================
    // Funções de Escrita (sem taxa)
    // ====================
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

    // ====================
    // Funções de Administração
    // ====================
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Endereco invalido");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    function setFeeRate(uint256 newRate) external onlyAdmin {
        require(newRate <= 2000, "Taxa maxima 20%");
        feeRate = newRate;
        emit FeeRateUpdated(newRate);
    }

    // ====================
    // Funções Auxiliares
    // ====================
    receive() external payable {}
}
