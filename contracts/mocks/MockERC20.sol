// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockPUNK is ERC20 {
    constructor(address initialAccount) ERC20("KNUP Token", "KNUP") {
        _mint(initialAccount, 10000000 * (10 ** uint256(decimals())));
    }
}
