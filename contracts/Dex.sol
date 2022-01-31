pragma solidity 0.6.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
pragma experimental ABIEncoderV2;

contract Dex {
    
    using SafeMath for uint;

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    event NewTrade (
        uint tradId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }

    bytes32 constant DAI = bytes32('DAI');
    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    bytes32[] public tokenList;
    address public admin;
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    uint public nextOrderId;
    uint public nextTradeId;

    constructor() public {
        admin = msg.sender;
    }

    function getOrders(bytes32 ticker, Side side) external view returns(Order[] memory) {
        return orderBook[ticker][uint(side)];
    }

    function getTokens() external view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](tokenList.length);
        for (uint i = 0; i < tokenList.length; i++) {
            _tokens[i] = Token(
                tokens[tokenList[i]].ticker,
                tokens[tokenList[i]].tokenAddress
            );
        }
      
        return _tokens;
    }

    function addToken(bytes32 ticker, address tokenAddress) adminOnly() external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    function createMarketOrder(bytes32 ticker, uint amount, Side side) tokenExist(ticker) tokenIsNotDAI(ticker) external {
        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Balance it too low');
        }

        Order[] storage orders = orderBook[ticker][uint(side == Side.BUY ? Side.SELL : Side.BUY)];
        uint i = 0;
        uint remainder = amount;
        while (i < orders.length && remainder > 0) {
            uint availabe = orders[i].amount = orders[i].amount.sub(orders[i].filled);
            uint matched = (remainder > availabe) ? availabe : remainder;
            remainder = remainder.sub(matched);
            orders[i].filled = orders[i].filled.add(matched);
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                ticker,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                block.timestamp
            );
            if (side == Side.SELL) {
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].add(matched.mul(orders[i].price));
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].add(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].sub(matched.mul(orders[i].price));
            }

            if (side == Side.BUY) {
                require(
                    traderBalances[msg.sender][DAI] >= matched.mul(orders[i].price),
                    'dai balance too low'
                );
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].sub(matched * orders[i].price);
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].sub(
                    traderBalances[orders[i].trader][ticker].add(matched)
                );
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].add(
                    traderBalances[orders[i].trader][DAI].sub(matched.mul(orders[i].price))
                );
            }
            nextTradeId = nextTradeId.add(1);
            i = i.add(1);

            i = 0;
            while(i < orders.length && orders[i].filled == orders[i].amount) {
                for(uint j = i; j < orders.length - 1; j++ ) {
                    orders[j] = orders[j + 1];
                }
                orders.pop();
                i++;
            }
        }
    }

    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);

        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }

    function createLimitOrder(bytes32 ticker, uint amount, uint price, Side side) tokenExist(ticker) tokenIsNotDAI(ticker) external {

        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Balance it too low');
        } else {
            require(traderBalances[msg.sender][DAI] >= amount.mul(price), 'DAI Balance is too low');
        }

        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            ticker,
            amount,
            0,
            price,
            block.timestamp
        ));

        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while (i > 0) {
            if (side == Side.BUY && orders[i].price > orders[i].price) {
                break;
            }
            if (side == Side.SELL && orders[i].price < orders[i].price) {
                break;
            }

            Order memory temp = orders[i];
            orders[i] = orders[i - 1];
            orders[i - 1] = temp;
            i = i.sub(1);
        }

        nextOrderId = nextOrderId.add(1);
    }

    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(traderBalances[msg.sender][ticker] >= amount, 'In sufficient funds');
        
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    modifier tokenIsNotDAI(bytes32 ticker) {
        require(ticker != DAI, 'Cannot exchange DAI');
        _;
    }
    modifier tokenExist(bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0), "this token does not exist");
        _;
    }

    modifier adminOnly() {
        require(msg.sender == admin, 'Unauthorized transfer');
        _;
    }
}