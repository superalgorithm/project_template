#!/bin/bash

# Load environment variables from .env file
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
strategies=($(git ls-files --others --exclude-standard --directory ./src | grep -v './src/common/' | xargs -n 1 basename))

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
}

# Function to upload changes using scp
upload_changes() {
    local strategy=$1

    echo "Uploading changes for $strategy..."
    rsync -av --exclude-from='.gitignore' --exclude-from='.dockerignore' ./src/$strategy $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/src/
    rsync -av --exclude-from='.gitignore' --exclude-from='.dockerignore' ./src/common $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/src/
}

# Function to run docker-compose to update the strategy
update_strategy() {
    local strategy=$1

    echo "Updating $strategy..."

    ssh $REMOTE_USER@$REMOTE_HOST "
        cd / && cd $REMOTE_PATH/src/common &&
        docker build -t common_code_image:latest . &&
        cd / && cd $REMOTE_PATH/src/$strategy &&
        docker build -t $strategy . &&

        if [ \$(docker ps -a -q -f name=^${strategy}\$) ]; then
            docker stop $strategy &&
            docker rm $strategy 2>/dev/null || echo "Container $strategy already removed"
        else
            echo "No container with name $strategy found."
        fi &&
        docker run -d -it --rm --name $strategy $strategy python main.py
    "
}

# Main script execution
select_strategy
upload_changes $strategy
update_strategy $strategy

echo "Deployment of $strategy completed."