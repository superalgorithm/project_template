#!/bin/bash
# chmod +x deploy.sh

strategies=($(find src -maxdepth 1 -type d -not -name "src" -not -name "common" -not -name "__pycache__" -not -name ".pytest_cache" -not -name "*.egg-info" -exec basename {} \;))

select_strategy() {
    echo "Select a strategy to run:"
    select strategy in "${strategies[@]}"; do
        if [[ " ${strategies[@]} " =~ " ${strategy} " ]]; then
            echo "You selected $strategy"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

select_mode() {
    echo "Select a mode to run:"
    options=("Backtest" "Live Strategy")
    select mode in "${options[@]}"; do
        case $mode in
            "Backtest")
                echo "You selected Backtest"
                startup_script="python backtest.py"
                break
                ;;
            "Live Strategy")
                echo "You selected to run the strategy"
                startup_script="python main.py"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
}

stop_and_remove_container() {
    local strategy=$1
    echo "Stopping and removing existing container for $strategy..."
    
    if [ "$(docker ps -q --filter "name=$strategy")" ]; then
        docker stop $strategy
    fi

    if [ "$(docker ps -aq --filter "name=$strategy")" ]; then
        docker rm $strategy
    fi

    docker image prune -f
}

build_common() {
  echo "Building common code image..."
  DOCKER_BUILDKIT=1 docker build -t common_code_image:latest ./src/common
}

build_image() {
    local strategy=$1
  
    stop_and_remove_container $strategy

    echo "Building image for $strategy..."

    DOCKER_BUILDKIT=1 docker build --rm -t $strategy ./src/$strategy
    
    docker run -p 5678:5678 -d -it --rm --name $strategy -e SUPER_STRATEGY_ID=$strategy $strategy $startup_script

    docker logs -f $strategy &
    LOG_PID=$!
}


watch_for_changes() {
    local strategy=$1

    fswatch -o ./src/common | while read; do
        echo "Changes detected in common. Rebuilding common image..."
        build_common
        build_image $strategy
    done &

    fswatch -o -e ".*common.*" "./src/$strategy" | while read f
    do
      echo "Changes detected in $strategy. Rebuilding image..."
      kill $LOG_PID
      build_image $strategy
    done
}


main() {

  select_strategy

  trap "stop_and_remove_container $strategy" EXIT
  trap "stop_and_remove_container $strategy" SIGINT

  select_mode
  build_common
  build_image $strategy
  watch_for_changes $strategy
}

main "$@"