// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GymToken is ERC20 {

    constructor() ERC20("GYMBO TOKEN", "GYM") {
       _mint(msg.sender, 1000000000000000000000000); 
    }
}
