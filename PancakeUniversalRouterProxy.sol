// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniversalRouter {
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
    function collectRewards() external;
    function pancakeV3SwapCallback() external;
    function pause() external;
    function renounceOwnership() external;
    function setStableSwap(address factory, bool status) external;
    function transferOwnership(address newOwner) external;
    function unpause() external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract PancakeSwapProxy {
    address public admin;
    IUniversalRouter public immutable universalRouter;
    uint256 public feePercentage; // Fee in basis points (e.g., 1000 = 10%)
    bool public paused;
    address public owner;
    address public stableSwapFactory;
    mapping(address => bool) public stableSwapInfo;

    event FeeUpdated(uint256 newFeePercentage);
    event AdminUpdated(address newAdmin);
    event FeeCollected(address indexed sender, uint256 amount);
    event Paused();
    event Unpaused();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event StableSwapSet(address indexed factory, bool status);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(address _universalRouter, address _admin, uint256 _feePercentage) {
        require(_universalRouter != address(0), "Invalid router address");
        require(_admin != address(0), "Invalid admin address");
        require(_feePercentage <= 10000, "Fee too high");

        universalRouter = IUniversalRouter(_universalRouter);
        admin = _admin;
        owner = _admin;
        feePercentage = _feePercentage;
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function updateFee(uint256 _newFeePercentage) external onlyAdmin {
        require(_newFeePercentage <= 10000, "Fee too high");
        feePercentage = _newFeePercentage;
        emit FeeUpdated(_newFeePercentage);
    }

    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable whenNotPaused {
        uint256 feeAmount = (msg.value * feePercentage) / 10000;
        uint256 newValue = msg.value - feeAmount;
        payable(admin).transfer(feeAmount);
        emit FeeCollected(msg.sender, feeAmount);
        universalRouter.execute{value: newValue}(commands, inputs, deadline);
    }

    function collectRewards() external onlyAdmin {
        universalRouter.collectRewards();
    }

    function pancakeV3SwapCallback() external {
        universalRouter.pancakeV3SwapCallback();
    }

    function pause() external onlyAdmin {
        universalRouter.pause();
        paused = true;
        emit Paused();
    }

    function unpause() external onlyAdmin {
        universalRouter.unpause();
        paused = false;
        emit Unpaused();
    }

    function transferOwnership(address newOwner) external onlyAdmin {
        require(newOwner != address(0), "Invalid owner address");
        universalRouter.transferOwnership(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyAdmin {
        universalRouter.renounceOwnership();
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function setStableSwap(address factory, bool status) external onlyAdmin {
        universalRouter.setStableSwap(factory, status);
        stableSwapInfo[factory] = status;
        stableSwapFactory = factory;
        emit StableSwapSet(factory, status);
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    receive() external payable {}
}
