# PancakeProxy Contract

The `PancakeProxy` is a Solidity smart contract that interacts with the PancakeSwap V2 Router to add/remove liquidity, swap tokens, and perform swap operations on PancakeSwap, while adding an additional 10% fee on top of the transaction fee, which is sent to the admin's address. This contract allows the admin to change the fee percentage (`feePercentage`) and the admin address.

## Features

- **Add and Remove Liquidity**: The contract interacts directly with PancakeSwap V2 to add and remove liquidity for token pairs or with ETH.
- **Token Swaps**: The contract allows swapping tokens for ETH or other tokens.
- **Fee Management**: The contract applies a 10% fee on the PancakeSwap transaction fee, which is sent to the admin's address.
- **Admin Control**: The admin can change the fee percentage and admin address.

## Detailed Features

### 1. **Add Liquidity**
- `addLiquidity`: Adds liquidity to a token pair.
- `addLiquidityETH`: Adds liquidity to a token pair with ETH.

### 2. **Remove Liquidity**
- `removeLiquidity`: Removes liquidity from a token pair.
- `removeLiquidityETH`: Removes liquidity from a token pair with ETH.
- `removeLiquidityETHSupportingFeeOnTransferTokens`: Removes liquidity considering tokens with transfer fees.
- `removeLiquidityETHWithPermit`: Removes liquidity with permit.
- `removeLiquidityETHWithPermitSupportingFeeOnTransferTokens`: Removes liquidity with permit considering tokens with transfer fees.

### 3. **Token Swaps**
- `swapExactETHForTokens`: Swaps ETH for tokens.
- `swapExactTokensForETH`: Swaps tokens for ETH.
- `swapExactTokensForTokens`: Swaps tokens for other tokens.
- `swapTokensForExactTokens`: Swaps an exact number of tokens for another exact number of tokens.
- `swapExactETHForTokensSupportingFeeOnTransferTokens`: Swaps ETH for tokens with transfer fees.
- `swapETHForExactTokens`: Swaps ETH for an exact number of tokens.

### 4. **Fee Management**
- The contract applies a 10% fee on the PancakeSwap transaction fee, which is sent to the admin's address.

### 5. **Admin Control**
- The admin can change the admin address using the `setAdmin` function.
- The admin can adjust the transaction fee percentage with the `setFeePercentage` function, with a maximum of 100%.

## Key Functions

### 1. `setFeePercentage(uint _feePercentage)`
Allows the admin to change the transaction fee percentage (in whole numbers, from 0 to 100%).

### 2. `setAdmin(address _admin)`
Allows the admin to change the admin address, ensuring only the current admin has permission.

### 3. `_applyFee(uint ethAmount)`
Applies the admin fee on the transaction amount and sends it to the admin address.

## Fee Flow

Each time a transaction interacts with the PancakeSwap swap or liquidity functions, the contract deducts a 10% fee from the transaction amount (in ETH) and sends this fee to the admin address.

## Example Usage

1. **Add Liquidity with ETH**:

```solidity
pancakeProxy.addLiquidityETH(
    tokenAddress, 
    amountTokenDesired, 
    amountTokenMin, 
    amountETHMin, 
    toAddress, 
    deadline
);
```

2. **Remove Liquidity with Tokens**:

```solidity
pancakeProxy.removeLiquidityETH(
    tokenAddress, 
    liquidity, 
    amountTokenMin, 
    amountETHMin, 
    toAddress, 
    deadline
);
```

3. **Swap ETH for Tokens**:

```solidity
pancakeProxy.swapExactETHForTokens(
    amountOutMin, 
    path, 
    toAddress, 
    deadline
);
```

4. **Change Admin**:

```solidity
pancakeProxy.setAdmin(newAdminAddress);
```

5. **Change Fee**:

```solidity
pancakeProxy.setFeePercentage(newFeePercentage);
```

## Examples

Testnet BSC: [PancakeProxy](https://testnet.bscscan.com/address/0xe9c471fe397d1ae5dd2f83576a22b423312d95b0#code)

## Technical Details

- **Solidity Version**: `^0.8.0`
- **PancakeSwap V2 Interface**: `IPancakeRouterV2`
- **Default Admin Fee**: 10%
- **Admin**: The admin address can be changed at any time by the current admin.

## Security

The contract applies a 10% fee on transactions, which is sent to the admin's address. Only the admin can change the fee or admin address. The contract does not allow changes to other parameters, ensuring restricted and secure transaction control.

## Final Considerations

This contract is a simplified implementation to facilitate interaction with PancakeSwap V2, maintaining transparent operations and allowing the admin to have control over the fee applied to transactions. The solution can be extended according to business needs.

---

## Copyright

Copyright (c) Diego Oris <diegoantunes2301@gmail.com>

## Blockchain or Web3 Project Recommendations

If you're looking to create your own blockchain or Web3 project, consider reaching out to [Better2Better](https://better2better.tech). They provide professional services to help you build, scale, and optimize your decentralized applications and smart contracts.
