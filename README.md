# Super Algorithm Project Template

An opinionated project template for building and testing trading strategies.

> **Disclaimer:** This project is for educational purposes only. It is not intended to provide financial advice. The authors are not responsible for any financial losses incurred while using this project.

# Features

- build common modules and use them across different trading strategies
- isolate code and dependencies for each trading strategy
- locally run strategies and backtests with hot reloads
- deploy strategies to a remote server

# System Requirements

Requires [Docker](https://www.docker.com/) running on the development machine as well as the remote host.

Requires fswatch for watching folders and automatically re-building the containers during development mode.

```
brew install fswatch
```

# Installation

Clone the repository to your local machine.

Make the scripts executable

```
chmod +x deploy.sh
chmod +x develop.sh
```

# Usage

```
src/
 - common           <- base docker image
    - helper.py
    - custom_libary.py
 - strategy_1
    - main.py
    - backtest.py
 - strategy_2
 - my_new_strategy
```

### - common

Every strategy is build from the `common` base Docker image. This means all code you place in the `common` module, as well as any modules defined in `common/requirements.txt` will be available to all strategies.

### - common / tests

All tests placed in the `common/tests` folder run during the docker build process. If a test fails, the build will fail.

### - strategy folders

All other folders inside the `src/` folder are considerd to be strategies. Each strategy has their own `Dockerfile`, `requirements.txt` and two entry scripts `main.py` and `backtest.py`.

Having a `requirements.txt` for each strategy allows you to further lock dependencies i.e. one strategy could run with superalgorithm==1.0.2 and another one could use superalgorithm==1.8.2 etc.

> **Warning:** Any changes you make in `src/common` will apply to **all** strategies. Make sure your common code is tested and changes don't break strategies.

#### main.py

`main.py` this script should be used to run a strategy during test and live trading.

#### backtest.py

`backtest.py` use this to configure and run backtests.

## ./develop.sh

Will scan the src folder and list all strategies (folders except 'common')

After strategy selection will provide option to:

1. Backtest
2. Run Strategy

Both options will build the docker images and run either the `backtest.py` or `main.py` scripts for the selected strategy on your local computer.

Any changes to the files in the selected strategy folder or `common` will trigger an automated re-build.

## ./deploy.sh

### First, configure your remote host settings in `.env`

```
REMOTE_USER=<username>
REMOTE_HOST=<ip addreess>
REMOTE_PATH=<path to installtion folder>
```

Ensure you have SSH access to your remote server. Check this guide or consult with your hosting provider. [How to Add SSH Keys to New or Existing Droplets](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/)

Ensure docker is installed on your remote host. [For example: Digital Ocean One Click Docker Droplet](https://marketplace.digitalocean.com/apps/docker)

### Select the strategy you like to deploy.

This will upload the common folder and the selected strategy source files.

> **Warning:** Any files listed in .gitignore or .dockerignore are not uploaded.

Once uploaded it will build and run the docker containers and run `main.py`.

### You can verify the strategy is ssh into your server

```
ssh root@<your ip address>
```

Then run the below command to show the logs

```
docker logs -f <strategy_name>
```

> **Attention:** Don't forget to manually upload any .env or config.yaml files your strategy may require to run.
