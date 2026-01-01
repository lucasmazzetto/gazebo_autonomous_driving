#!/bin/bash
IMAGE_NAME=gazebo_autonomous_driving
IMAGE_TAG=harmonic
CONTAINER_NAME=gazebo_autonomous_driving

if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        # Container is running: attach..."
        docker exec -it $CONTAINER_NAME  bash -i
    else
        # Container exists but is stopped: start and attach
        docker start -ai $CONTAINER_NAME
    fi
else
    # Run the container
    docker run -it \
    --name ${CONTAINER_NAME} \
    --privileged \
    --runtime=nvidia \
    --env DISPLAY=$DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    --env XAUTHORITY=/tmp/.docker.xauth \
    --env ROS_DOMAIN_ID=0 \
    --env HISTFILE=/home/ros/.bash_history \
    --env HISTFILESIZE=10000 \
    --env RCUTILS_COLORIZED_OUTPUT=1 \
    --env GZ_VERSION=harmonic \
    --env NVIDIA_VISIBLE_DEVICES=all \
    --env NVIDIA_DRIVER_CAPABILITIES=all,graphics,display,video,utility,compute \
    --env __NV_PRIME_RENDER_OFFLOAD=1 \
    --env __GLX_VENDOR_LIBRARY_NAME=nvidia \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/input:/dev/input \
    -v /dev/dri:/dev/dri \
    -v /dev/nvidia0:/dev/nvidia0 \
    -v /dev/nvidiactl:/dev/nvidiactl \
    -v /dev/nvidia-modeset:/dev/nvidia-modeset \
    -v /dev/nvidia-modeset:/dev/nvidia-modeset \
    -v ~/autopilot_neural_network/model.pt:/tmp/autopilot_neural_network/model.pt \
    -v ~/autopilot_neural_network/dataset:/tmp/autopilot_neural_network/dataset \
    $IMAGE_NAME:$IMAGE_TAG \
    bash -i
fi