#!/bin/bash

# Load hosting settings from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

# Start the ssh-agent and add the SSH key
eval "$(ssh-agent -s)"
ssh-add

# Get the list of strategies (folders inside ./src excluding common)
strategies=($(find src -maxdepth 1 -type d -not -name "src" -not -name "common" -not -name "__pycache__" -not -name ".pytest_cache" -not -name "*.egg-info" -exec basename {} \;))

# Function to display the menu and get user selection
select_strategy() {
    echo "Select a strategy to deploy:"
    select strategy in "${strategies[@]}"; do
        if [[ " ${strategies[@]} " =~ " ${strategy} " ]]; then
            echo "You selected $strategy"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
    check_strategy_settings "$strategy"
}

check_strategy_settings() {
    local strategy=$1
    local config_file="./src/$strategy/config.yaml"

    if [ -f "$config_file" ]; then
        echo "Checking for strategy_settings in $config_file..."
        if grep -q "strategy_settings:" "$config_file"; then
            echo "strategy_settings found in $config_file"
            parse_strategy_settings "$strategy" "$config_file"
        else
            echo "No strategy_settings found in $config_file"
            upload_changes $strategy
            update_strategy $strategy
        fi
    else
        echo "No config.yaml found for $strategy"
        upload_changes $strategy
        update_strategy $strategy
    fi
}

settings=()

parse_strategy_settings() {
    local strategy=$1
    local config_file="./src/$strategy/config.yaml"
    local env_vars=""

    if [ -f "$config_file" ]; then
        echo "Reading settings from $config_file..."
        
        settings_block=$(yq eval '.strategy_settings' "$config_file")

        if [ "$settings_block" == "null" ]; then
            echo "No 'strategy_settings' found in $config_file."
            return
        fi

        keys=$(echo "$settings_block" | yq eval 'to_entries | .[] | .key' -)
        values=$(echo "$settings_block" | yq eval 'to_entries | .[] | .value' -)

        IFS=$'\n' read -d '' -r -a key_array <<< "$keys"
        IFS=$'\n' read -d '' -r -a value_array <<< "$values"

        for ((i=0; i<${#key_array[@]}; i++)); do
            key="${key_array[i]}"
            value="${value_array[i]}"
            
            # Prompt user for input, showing current value
            read -p "Enter value for $key (current: $value): " user_input
            
            # If user input is empty, keep the original value
            if [[ -z "$user_input" ]]; then
                echo "Setting $key = $value"
                env_vars="$env_vars -e $key=$value"
            else
                echo "Setting $key = $user_input"
                env_vars="$env_vars -e $key=$user_input"
            fi
        done

        echo "Updated Configuration: $env_vars"
    fi

    upload_changes "$strategy"
    update_strategy "$strategy" "$env_vars"

}

# Function to upload changes using scp
upload_changes() {
    local strategy=$1

    echo "Uploading changes for $strategy..."
    rsync -av --exclude-from='.gitignore' --exclude-from='.dockerignore' ./src/$strategy $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/src/
    rsync -av --exclude-from='.gitignore' --exclude-from='.dockerignore' ./src/common $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/src/

    local config_path="./src/$strategy/config.yaml"
    
    # Prompt user about uploading config.yaml
    read -p "Do you want to upload config.yaml for $strategy? [y/N] " upload_config
    
    # Convert input to lowercase for case-insensitive comparison
    upload_config=$(echo "$upload_config" | tr '[:upper:]' '[:lower:]')
    
    if [ "$upload_config" = "y" ] || [ "$upload_config" = "yes" ]; then
        if [ -f "$config_path" ]; then
            echo "Uploading config.yaml for $strategy..."
            rsync -av "$config_path" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/src/$strategy/"
        else
            echo "Warning: config.yaml not found in $config_path"
        fi
    fi
}

# Function to run docker-compose to update the strategy
update_strategy() {
    local strategy=$1
    local env_vars=$2

    echo "Updating $strategy..."

    read -p "Enter instance name (default: $strategy): " instance_name
    instance_name=${instance_name:-$strategy}

    ssh $REMOTE_USER@$REMOTE_HOST "
        cd / && cd $REMOTE_PATH/src/common &&
        docker build -t common_code_image:latest . &&
        cd / && cd $REMOTE_PATH/src/$strategy &&
        docker build -t $strategy . &&

        if [ \$(docker ps -a -q -f name=${instance_name}\$) ]; then
            docker stop $instance_name &&
            docker rm $instance_name 2>/dev/null || echo 'Container $instance_name already removed'
        else
            echo 'No container with name $instance_name found.'
        fi &&
        docker run -d -it --rm --name $instance_name $env_vars -e SUPER_STRATEGY_ID=$instance_name $strategy python main.py
    "
}

# Main script execution
select_strategy

echo "Deployment of $strategy completed."