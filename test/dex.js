const Dai = artifacts.require('../contracts/mocks/Dai.sol');
const Bat = artifacts.require('../contracts/mocks/Bat.sol');
const Zrx = artifacts.require('../contracts/mocks/Zrx.sol');
const Rep = artifacts.require('../contracts/mocks/Rep.sol');

contract('Dex', () => {
    let dai, bat, zrx, rep;

    beforeEach(async () => {
        ([dai, bat, zrx, rep] = await Promise.all([
            Dai.new(),
            Bat.new(),
            Zrx.new(),
            Rep.new()
        ]));
    });
})
