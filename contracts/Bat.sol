pragma solidity 0.6.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Bat is ERC20 {
  constructor() ERC20('BAT', 'Brave browser Token') public {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
  
}