# uniswap-proxy-assignment

A UUPS-upgradeable smart contract that allows users to deposit ERC20 tokens and ETH, and creates a Uniswap V3 liquidity position on the zkSync Era Testnet.

---

## Features

- User deposits ERC20 token + ETH
- Contract creates a Uniswap V3 liquidity position via NonfungiblePositionManager
- Upgradeable via UUPS proxy pattern
- Fully deployable and testable on zkSync Era Testnet

---

## Setup

1. **Clone the repo**

```bash
git clone https://github.com/alexandralanorias/uniswap-proxy-assignment.git
cd uniswap-proxy-assignment
````

2. **Install dependencies**

```bash
npm install
```

3. **Configure your environment variables**

Create a `.env` file in the root directory:

```env
ZKSYNC_TESTNET_KEY=<your-wallet-private-key>
```

> !!!!! Never commit your `.env` file or private keys.

4. **Compile contracts**

```bash
npx hardhat compile --force
```

5. **Deploy contracts**

```bash
npx hardhat run scripts/deploy.js --network zkSyncTestnet
```

6. **Interact with deployed contracts**

Modify `scripts/interact.js` with your token and 'proxy' addresses, then:

```bash
npx hardhat run scripts/interact.js --network zkSyncTestnet
```

---

## Notes

* The `flat.sol` file was generated for verification purposes (but is unimplemented on the block explorer) and is included as a reference.
* Make sure to update the addresses in `interact.js` to match your deployed contracts.
* Gas costs and ETH values are dependent on the zkSync Era Testnet.

---

## License

MIT