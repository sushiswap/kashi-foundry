# Sushi Lending Foundry

## Prerequisites
- Foundry
- Make

## Getting Started

Initialize
```sh
make init
```

Make a copy of `.env.defaults` to `.env` and set the desired parameters.

* Uses Tenderly forks for testing, make sure to add the tenderly fork id to .env.defaults *

Build and Test.

```sh
make spinup
```

In another terminal:

```sh
make build
make test
```

## Deploy & Verify

## Installing Libs
```sh
forge install <git repo name><@optionnal_tag_or_commit_hash>
make remappings
```

### Update a lib
```
foundry update lib/<package>
```

## Updating Foundry
This will update to the latest Foundry release
```
foundryup
```

## Playground
Playground is a place to make quick tests. Everything that could be inside a normal test can be used there.
Use case can be to test out some gas optimisation, decoding some data, play around with solidiy, etc.
```
make playground
```






