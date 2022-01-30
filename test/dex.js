const Dai = artifacts.require('../contracts/mocks/Dai.sol');
const Bat = artifacts.require('../contracts/mocks/Bat.sol');
const Zrx = artifacts.require('../contracts/mocks/Zrx.sol');
const Rep = artifacts.require('../contracts/mocks/Rep.sol');
const Dex = artifacts.require('../contracts/Dex.sol');

contract('Dex', () => {
    let dai, bat, zrx, rep;

    const tickers = ['DAI', 'BAT', 'ZRX', 'REP'];
    const [DAI, BAT, ZRX, REP] = tickers.map(ticker => {
        return web3.utils.fromAscii(ticker);
    });

    beforeEach(async (accounts) => {
        const [trader1, trader2] = [accounts[1], accounts[2]];
        ([dai, bat, zrx, rep] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Zrx.new(),
            Rep.new()
        ]));
        
        const dex = await Dex.new();
        await Promise.all([
            dex.addToken(DAI, dai.address),
            dex.addToken(BAT, bat.address),
            dex.addToken(ZRX, zrx.address),
            dex.addToken(REP, rep.address)
        ]);

        const amount = web3.utils.toWei('1000');
        const seedTokenAccount = async (token, trader) => {
            await token.faucet(trader, amount);
            await token.approve(dex.address, amount, { from: trader });
        }

        Promise.all(
            [DAI, BAT, ZRX, REP].map(token => {
                seedTokenAccount(token, trader1);
                seedTokenAccount(token, trader2);
            })
        );
    });
})
