#!/bin/bash

# Define the image name
IMAGE_NAME="ninja-api/bazaar-backend"

# Locate dockerfile last modified cache file
DOCKER_LAST_MODIFIED="./.docker-cache/dockerfile_lastmodified.txt"

# Define functions

# Function to build the Docker image
build_image() {
    echo "Building the Docker image..."
    docker image rm $IMAGE_NAME
    docker build . --rm -t $IMAGE_NAME
    stat -c %Y Dockerfile > $DOCKER_LAST_MODIFIED
}

remove_untagged() {
    echo "Locating and removing untagged images and containers..."

    # First get a list of all untagged images
    UNTAGGED_IMAGES=$(docker images | grep "<none>" | awk '{print $3}')

    if [[ -z "$UNTAGGED_IMAGES" ]]; then
        echo "No untagged images found."
    else
        echo "Untagged images found: $UNTAGGED_IMAGES"
    fi
    # Get all container IDs using untagged images
    for UNTAGGED_IMAGE in $UNTAGGED_IMAGES; do
        echo "Untagged image ID: $UNTAGGED_IMAGE"
        UNTAGGED_CONTAINERS=$(docker ps --all -q --filter ancestor=$UNTAGGED_IMAGE)
                
        # Check if no untagged containers in UNTAGED_CONTAINERS

        if [[ -z "$UNTAGGED_CONTAINERS" ]]; then
            echo "No untagged containers found."
        else
            # Iterate through each untagged container ID
            for UNTAGGED_CONTAINER in $UNTAGGED_CONTAINERS; do
                echo "Untagged container ID: $UNTAGGED_CONTAINER"
                # Stop the untagged container
                echo "Stopping untagged container ID: $UNTAGGED_CONTAINER"
                docker stop $UNTAGGED_CONTAINER
                # Remove the untagged container
                echo "Removing untagged container ID: $UNTAGGED_CONTAINER"
                docker rm $UNTAGGED_CONTAINER
            done
        fi
    done

    # Finally, remove all untagged images
    for UNTAGGED_IMAGE in $UNTAGGED_IMAGES; do
        echo "Removing untagged image: $UNTAGGED_IMAGE"
        docker rmi $UNTAGGED_IMAGE
    done
}

# Function to stop running containers
stop_containers() {
    # First get all container IDs using image
    CONTAINER_IDS=$(docker ps --all -q --filter ancestor=$IMAGE_NAME)

    # Check if no containers in CONTAINER_IDS
    if [[ -z "$CONTAINER_IDS" ]]; then
        echo "No containers found."
    else
        # Iterate through each container ID
        for CONTAINER_ID in $CONTAINER_IDS; do
            echo "Container ID: $CONTAINER_ID"
            # Check if the container is running
            if [[ "$(docker inspect -f '{{.State.Status}}' $CONTAINER_ID)" == "running" ]]; then
                # Stop the container
                echo "Stopping container ID: $CONTAINER_ID"
                docker stop $CONTAINER_ID
            else
                echo "Container ID: $CONTAINER_ID is not running."
            fi
        done
    fi
}

# Remove all stopped containers
remove_containers() {
    # Get all container IDs of stopped containers using image
    STOPPED_CONTAINER_IDS=$(docker ps --all -q --filter ancestor=$IMAGE_NAME --filter status=exited)

    # Check if no stopped containers in STOPPED_CONTAINER_IDS
    if [[ -z "$STOPPED_CONTAINER_IDS" ]]; then
        echo "No stopped containers found."
    else
        # Iterate through each stopped container ID
        for STOPPED_CONTAINER_ID in $STOPPED_CONTAINER_IDS; do
            echo "Stopped container ID: $STOPPED_CONTAINER_ID"
            # Remove the stopped container
            echo "Removing stopped container ID: $STOPPED_CONTAINER_ID"
            docker rm $STOPPED_CONTAINER_ID
        done
    fi
}

# Function to check if Dockerfile has been modified and build the image if necessary
build_if_modified() {
    # First check if the Dockerfile has been modified
    if [[ "$(stat -c %Y Dockerfile)" != "$(cat $DOCKER_LAST_MODIFIED 2> /dev/null)" ]]; then
        echo "Dockerfile has been modified. First, stopping and removing all relevant containers..."
        stop_containers
        remove_containers
        echo "Building the Docker image..."
        
        build_image
        # Update the cache file with the new modification timestamp
        
    else
        echo "Dockerfile has not been modified since the last build."
    fi
}

# Look for untagged containers, stop and remove them
remove_untagged

# Check if the image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Image $IMAGE_NAME does not exist. Building the image..."
    build_image
else
    echo "Image $IMAGE_NAME already exists."
    build_if_modified
fi

# Run the Docker image
echo "Running the Docker image..."
docker run -d --name "bazaar-backend" $IMAGE_NAME



