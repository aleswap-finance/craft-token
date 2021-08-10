// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
// pragma solidity =0.6.2;
import '@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol';

contract CraftToken is ERC20PresetMinterPauser {
    constructor()
        public
        ERC20PresetMinterPauser("Craft Token", "CRAFT")
    {
        _setupDecimals(18);
    }       
}
