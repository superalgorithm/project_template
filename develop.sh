#!/bin/bash
# chmod +x deploy.sh

strategies=($(git ls-files --others --exclude-standard --directory ./src | grep -v './src/common/' | xargs -n 1 basename))

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

    docker rm $strategy
    docker image prune -f
}

build_common() {
  echo "Building common code image..."
  docker build -t common_code_image:latest ./src/common
}

build_image() {
    local strategy=$1
  
    stop_and_remove_container $strategy

    echo "Building image for $strategy..."
    
    docker build --rm -t $strategy ./src/$strategy
    docker run -d -it --rm --name $strategy $strategy $startup_script

    docker logs -f $strategy &
    LOG_PID=$!
}


watch_for_changes() {
    local strategy=$1

    fswatch -o ./src/common | while read; do
        echo "Changes detected in common. Rebuilding common image..."
        build_common
    done &

    fswatch -o ./src/ | while read f
    do
      echo "Changes detected in $strategy. Rebuilding image..."
      kill $LOG_PID
      build_image $strategy
      sleep 1
    done
}


main() {
  select_strategy
  select_mode
  build_common
  build_image $strategy
  watch_for_changes $strategy
}

main "$@"