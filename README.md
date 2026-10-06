# Corepack stale cache repro

Corepack 0.36.0 runs a pnpm 12 that Corepack 0.34.0 cached, and crashes with `Cannot find module '.../bin/pnpm.cjs'`.

## Steps

```sh
git clone https://github.com/abappi19/corepack-stale-cache-repro && cd corepack-stale-cache-repro
./repro.sh
```

The script uses its own `COREPACK_HOME` (`.corepack-home/`) and pinned Corepack versions through `npx`, so the global Corepack and cache aren't involved.

1. `npx corepack@0.34.0 install` caches `pnpm@12.2.1` (pinned in `package.json`).
2. `npx corepack@0.36.0 pnpm --version` runs it.

Or skip 0.34.0: run `npx corepack@0.36.0 install`, change `bin` in `.corepack-home/v1/pnpm/12.2.1/.corepack` to `./bin/pnpm.cjs`, then run `npx corepack@0.36.0 pnpm --version`.

## Expected

`12.2.1`

## Actual

```
### cached record vs files on disk
{"locator":{...},"bin":{"pnpm":"./bin/pnpm.cjs","pnpx":"./bin/pnpx.cjs"},"hash":"sha512..."}
pnpm.mjs
pnpx.mjs
### npx corepack@0.36.0 pnpm --version
Error: Cannot find module '<repo>/.corepack-home/v1/pnpm/12.2.1/bin/pnpm.cjs'
  code: 'MODULE_NOT_FOUND'
BUG REPRODUCED
```

`repro.sh` exits 1 when the bug reproduces. The CI job `reproduces-bug` runs it on ubuntu-latest and macos-latest and passes while the bug exists.

## Versions

- Node 24 (seen on 24.11.0, which bundles Corepack 0.34.0)
- Corepack 0.34.0 writes the record; 0.36.0 (the latest) reads it
- pnpm 12.2.1

## Cause

- Corepack 0.34.0 maps every pnpm >=6 to `./bin/pnpm.cjs` ([config.json](https://github.com/nodejs/corepack/blob/0b492c9c97e4b3d5e9a139eeedb931860127b470/config.json#L79-L83)) and writes that into the cache's `.corepack` file. pnpm 12 only ships `bin/pnpm.mjs`; newer Corepack maps pnpm >=11 to it ([config.json](https://github.com/nodejs/corepack/blob/d4dcb1f89741603e776bba9d457425750fa26987/config.json#L96-L100)).
- `installVersion` reuses the cached `.corepack` `bin` without checking that the file exists ([corepackUtils.ts](https://github.com/nodejs/corepack/blob/d4dcb1f89741603e776bba9d457425750fa26987/sources/corepackUtils.ts#L214-L227)), and `runVersion` then loads the missing file.

Workaround: delete the cached version (`rm -rf ~/.cache/node/corepack/v1/pnpm/12.2.1`, or `corepack cache clean`).
