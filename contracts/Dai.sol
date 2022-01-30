pragma solidity 0.6.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Dai is ERC20 {
  constructor() ERC20('DAI', 'Dai token') public {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}