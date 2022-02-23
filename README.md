# firehose-tendermint

Firehose integration for Tendermint chains

## Getting Started

To get started, first clone the repository and install all dependencies:

```bash
git clone git@github.com:figment-networks/firehose-tendermint.git
go mod download
```

Once done, let's build the development binary:

```bash
make build
```

You should be able to use the `./build/firehose-tendermint` binary moving forward.

## Usage

To view usage and flags, run: `./build/firehose-tendermint help`.

```
Firehose services for Tendermint-based blockchains

Usage:
  firehose-tendermint [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  init        Initialize local configuration
  reset       Reset local data directory
  start       Starts all services at once
  tools       Developer tools

Flags:
      --common-auth-plugin string            Auth plugin URI, see streamingfast/dauth repository (default "null://")
      --common-blocks-store-url string       Store URL (with prefix) where to read/write (default "file://{fh-data-dir}/storage/merged-blocks")
      --common-blockstream-addr string       GRPC endpoint to get real-time blocks (default "0.0.0.0:9010")
      --common-first-streamable-block uint   First streamable block number
      --common-metering-plugin string        Metering plugin URI, see streamingfast/dmetering repository (default "null://")
      --common-oneblock-store-url string     Store URL (with prefix) to read/write one-block files (default "file://{fh-data-dir}/storage/one-blocks")
      --common-shutdown-delay duration       Add a delay between receiving SIGTERM signal and shutting down apps. Apps will respond negatively to /healthz during this period (default 5ns)
      --common-startup-delay duration        Delay before launching firehose process
  -c, --config string                        Configuration file for the firehose (default "firehose.yml")
  -d, --data-dir string                      Path to data storage for all components of firehose (default "./fh-data")
  -h, --help                                 help for firehose-tendermint
      --log-format string                    Logging format (default "text")
  -v, --verbose int                          Enables verbose output (-vvvv for max verbosity) (default 3)
      --version                              version for firehose-tendermint

Use "firehose-tendermint [command] --help" for more information about a command.
```

## Configuration

If you wish to use a configuration file instead of setting all CLI flags, you may create a new `firehose.yml`
file in your current working directory.

Example:

```yml
start:
  args:
    - ingestor
    - merger
    - relayer
    - firehose
  flags:
    # Common flags
    common-first-streamable-block: 1

    # Ingestor specific flags
    ingestor-mode: node
    ingestor-node-path: path/to/node/bin
    ingestor-node-args: start --x-crisis-skip-assert-invariants
    ingestor-node-env: "KEY=VALUE,KEY=VALUE"
```

### Service Ports

By default, `firehose-tendermint` will start all available services, each providing a
GRPC interface.

- `9000` - Ingestor
- `9010` - Relayer
- `9020` - Merger
- `9030` - Firehose

## License

Apache License 2.0