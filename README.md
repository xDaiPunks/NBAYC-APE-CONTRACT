# NBAYC Ape NFT Contract

The Ape NFT contract is an ERC-721 contract. The total supply is 10.000 tokens. Each token has attributes and a rarity rank.
The rarity rank follows the rarirty rank of the BAYC nft contract and can be found on https://raritysniper.com/bored-ape-yacht-club

The minting of tokens consist of 2 phases.

The first phase is the claim phase which will start on May 18th 2023 at 16:00 UTC. The claim phase will end on May 24th 2023 at 16:00 UTC
During this phase, whitelisted addresse from the claim list will be able to claim 1 or 2 NFTs. The whitelisted addresses can be found on https://nbayc.io/gc/claim-list/

The second phase is the mint phase which will start on May 24th 2023 at 16:00 UTC. More details on: https://nbayc.io/gc/

## Compiling the contract

Install dependencies

```sh
npm i
```

Run HardHat compile

```sh
npx npx hardhat compile
```

## Remix

To interact with this contract using Remix IDE (https://remix.ethereum.org/) using your local file system, you can install the remixd package.

```sh
npm install -g @remix-project/remixd
```

After install you can start remixd by issuing the followinng command:

```sh
remixd -s ~/YOUR-CONTRACT-DIRECTORY --remix-ide https://remix.ethereum.org/

```

Then in the Remix IDE choose 'localhost' as workspace and connect. You can also use your local ganache instance with Remix IDE. To do so, select 'Web3 Provider' for the environment. Make sure to have ganache-cli running
