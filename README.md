# rns-contracts

The collections of smart contracts that power the Ronin Name Service (RNS).

## Development

### Requirement

- [Foundry forge@^0.2.0](https://book.getfoundry.sh/)

### Build & Test

- Install packages

```shell
$ forge install
```

- Build contracts

```shell
$ forge build
```

- Run test

```shell
$ forge test
```

### Deploy

```shell
$ forge script <path/to/file.s.sol> -f --private-key <your_private_key>
```
