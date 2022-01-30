pragma solidity 0.8.11;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Bat is ERC20 {
  constructor() ERC20('BAT', 'Brave browser Token') {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
  
}