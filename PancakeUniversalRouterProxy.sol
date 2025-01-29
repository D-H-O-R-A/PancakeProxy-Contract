// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUniversalRouter {
    // Funções de Leitura
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function stableSwapFactory() external view returns (address);
    function stableSwapInfo() external view returns (bytes memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    
    // Funções de Escrita
    function collectRewards(bytes32[] calldata rewardIds) external payable;
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
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
        feeRate = 1000;
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
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSignature(
            "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)",
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
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSignature(
            "onERC1155Received(address,address,uint256,uint256,bytes)",
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
        (bool success, bytes memory result) = universalRouter.staticcall(abi.encodeWithSignature(
            "onERC721Received(address,address,uint256,bytes)",
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
        uint256 fee = (msg.value * feeRate) / 10000;
        _sendFee(fee);
        
        IUniversalRouter(universalRouter).collectRewards{value: msg.value - fee}(rewardIds);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs) external payable {
        uint256 fee = (msg.value * feeRate) / 10000;
        _sendFee(fee);
        
        IUniversalRouter(universalRouter).execute{value: msg.value - fee}(commands, inputs);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable {
        uint256 fee = (msg.value * feeRate) / 10000;
        _sendFee(fee);
        
        IUniversalRouter(universalRouter).execute{value: msg.value - fee}(commands, inputs, deadline);
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external payable {
        uint256 fee = (msg.value * feeRate) / 10000;
        _sendFee(fee);
        
        (bool success, ) = universalRouter.call{value: msg.value - fee}(abi.encodeWithSignature(
            "pancakeV3SwapCallback(int256,int256,bytes)",
            amount0Delta, amount1Delta, data
        ));
        require(success, "Falha no callback");
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
    // Funções Internas
    // ====================
    function _sendFee(uint256 fee) internal {
        if(fee > 0) {
            payable(admin).transfer(fee);
            emit FeeCollected(admin, fee);
        }
    }

    // Garante recebimento de ETH
    receive() external payable {}
}
