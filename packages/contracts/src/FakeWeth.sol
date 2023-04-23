// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin/token/ERC20/ERC20.sol";

contract FakeWeth is ERC20 {
    constructor() ERC20("FakeWeth", "FWETH") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
