# Super Algorithm Project Template

An opinionated project template for building and testing trading strategies with Super Algorithm.

> **Disclaimer:** This project is for educational purposes only. It is not intended to provide financial advice. The authors are not responsible for any financial losses incurred while using this project.

## Features

- Develop and share common modules across multiple trading strategies
- Isolate code and dependencies for individual trading strategies
- Run strategies and backtests locally with hot reloading
- Deploy strategies to remote servers

## System Requirements

- [Docker](https://www.docker.com/) running on both the development machine and the remote host
- fswatch for watching folders and automatically re-building containers during development mode
- yq for reading config.yaml settings

Install fswatch using:

```
brew install fswatch
```

Install yq using:

```
brew install yq
```

## Installation

1. Clone the repository to your local machine.

2. Make the scripts executable:

```
chmod +x deploy.sh
chmod +x develop.sh
```

## Usage

Project structure:

```
src/
 - common           <- base docker image
    - helper.py
    - custom_library.py
 - strategy_1
    - main.py
    - backtest.py
 - strategy_2
 - my_new_strategy
```

### common

Every strategy is built from the `common` base Docker image. All code placed in the `common` module, as well as any modules defined in `common/requirements.txt`, will be available to all strategies.

### common / tests

All tests placed in the `common/tests` folder run during the Docker build process. If a test fails, the build will fail.

### Strategy folders

All other folders inside the `src/` folder are considered strategies. Each strategy has its own `Dockerfile`, `requirements.txt`, and two entry scripts: `main.py` and `backtest.py`.

Having a `requirements.txt` for each strategy allows you to lock dependencies independently, e.g., one strategy could run with superalgorithm==1.0.2 and another with superalgorithm==1.8.2.

> **Warning:** Any changes made in `src/common` will apply to **all** strategies. Ensure your common code is tested and changes don't break strategies.

#### main.py

`main.py` should be used to run a strategy during testing and live trading.

#### backtest.py

`backtest.py` is used to configure and run backtests.

#### config.yaml

Configure `strategy_settings` in your config.yaml to create a list of environment variables that can be set during deployment.

Example config.yaml:

```yaml

---
strategy_settings:
  ticker: HMSTR/USDT:USDT
  tick_size: 0.000001
  trading_capital: 600
  risk: 0.25
  trade_mode: SHORT
  etc: something
```

when you run `.deploy.sh` the script will ask you to provide values for any of the variables you set under `strategy_settings`, or keep the default values.

You can then load these settings in your main.py:

```python
from superalgorithm.utils.config import config

def get_setting(key):
   # load from environtment if None load from yaml
   return config.get(key) or config.get("strategy_settings", {}).get(key)

ticker = get_setting("ticker")
trading_capital = int(get_setting("trading_capital") or 0)

...

```

## ./develop.sh

This script will:

1. Scan the src folder and list all strategies (folders except 'common')
2. After strategy selection, provide options to:
   a. Backtest
   b. Run Strategy

Both options will build the Docker images and run either the `backtest.py` or `main.py` scripts for the selected strategy on your local computer.

Any changes to files in the selected strategy folder or `common` will trigger an automated re-build.

## ./deploy.sh

### Configure your remote host settings in `.env`:

```
REMOTE_USER=<username>
REMOTE_HOST=<ip address>
REMOTE_PATH=<path to installation folder>
```

Ensure you have SSH access to your remote server. Check [this guide](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/) or consult with your hosting provider.

Ensure Docker is installed on your remote host. For example, you can use a [Digital Ocean One-Click Docker Droplet](https://marketplace.digitalocean.com/apps/docker).

### Select the strategy you want to deploy

This will upload the common folder and the selected strategy source files.

> **Warning:** Any files listed in .gitignore or .dockerignore are not uploaded.

Once uploaded, it will build and run the Docker containers and execute `main.py`.

### Verify the strategy is running

SSH into your server:

```
ssh root@<your ip address>
```

Then run the following command to show the logs:

```
docker logs -f <strategy_name>
```

> **Attention:** Don't forget to manually upload any .env or config.yaml files your strategy may require to run.

# Changelog

## December 2024

- Added support for dynamic container deployments by specifying `strategy_settings` in config.yaml.
- Support for choosing container names to create multiple instances from the same image.
