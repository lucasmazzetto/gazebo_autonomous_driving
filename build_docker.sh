#!/bin/bash
IMAGE_NAME=gazebo_autonomous_driving
IMAGE_TAG=harmonic

docker build -t $IMAGE_NAME:$IMAGE_TAG . 