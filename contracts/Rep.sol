pragma solidity 0.6.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Rep is ERC20 {
  constructor() ERC20('REP', 'Augur Token') public {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}