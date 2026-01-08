# Gazebo Autonomous Driving

This repository provides an imitation learning training and inference package for autonomous driving simulation built with ROS 2 Jazzy Jalisco and Gazebo Harmonic. It includes a vehicle model simulation, multiple racing-track environments, tools for data collection, neural network training, and an autopilot node for autonomous driving inference.

![autonomous-driving](https://github.com/user-attachments/assets/49999351-1994-48db-906b-f1adadccbc3a)

For the complete documentation of this project’s development, including simulation setup, data collection, and training workflow, please refer to the full article here: 

[Autonomous Driving Vehicle Simulation](https://workabotic.com/2026/autonomous-driving-vehicle-simulation/)

A pretrained model is available for download if you want to quickly evaluate the system or skip the training step entirely. The model was trained in simulation using manual driving data collected in Gazebo and can be used directly with the provided autopilot inference node:

[Download pretrained model (model.pt)](https://huggingface.co/lucasmazzetto/autopilot_neural_network/resolve/main/model.pt)

In the next sections, you’ll find detailed instructions covering installation, environment setup, data collection, training, inference, and configuration.

## 💻 Installation

Clone this repository on your computer using ```--recurse-submodules```, as the project relies on Git submodules.

```bash
git clone --recurse-submodules git@github.com:lucasmazzetto/gazebo_autonomous_driving.git
```

After cloning the repository, you can set up and run the project using one of the following approaches:

- **[Linux Setup](#-linux-setup)**: Install and run the project on your system using Ubuntu and ROS 2, with all dependencies managed directly on the machine.

- **[Docker Setup](#-docker-setup)**: Use a Docker-based environment with all required dependencies preconfigured, avoiding manual system setup.

Both approaches are supported and described in the sections below.

## 🐧 Linux Setup

This project is designed to run on Linux Ubuntu 24.04, but it may also run on other Linux distributions, although additional adjustments might be required. 

After cloning the repository, move all its contents into the ROS 2 `workspace/src` directory. If you don't have a workspace set up, you can learn more about creating one in the [ROS 2 workspace tutorial](https://docs.ros.org/en/jazzy/Tutorials/Beginner-Client-Libraries/Creating-A-Workspace/Creating-A-Workspace.html).

```bash
mv gazebo_autonomous_driving/* <path_to_your_workspace>/src
```

### 📚 Requirements

To use this package, you'll need the following:

- [Linux Ubuntu 24.04](https://ubuntu.com/blog/tag/ubuntu-24-04-lts)
- [ROS 2 Jazzy Jalisco](https://docs.ros.org/en/rolling/Releases/Release-Jazzy-Jalisco.html)
- [Gazebo Harmonic](https://gazebosim.org/docs/harmonic/getstarted/)

**Make sure to install the following ROS 2 Jazzy Jalisco packages:**

```bash
sudo apt install -y \
     ros-jazzy-ros2-controllers \
     ros-jazzy-gz-ros2-control \
     ros-jazzy-ros-gz \
     ros-jazzy-ros-gz-bridge \
     ros-jazzy-joint-state-publisher \
     ros-jazzy-robot-state-publisher \
     ros-jazzy-xacro \
     ros-jazzy-joy                           
```

It is also required to install the Python dependencies using a virtual environment configured with access to system-wide Python packages. This configuration ensures compatibility with the ROS 2 Python ecosystem, as some dependencies are installed at the system level and must be available at runtime alongside the Python packages installed in the virtual environment. Create the virtual environment with system package access using the following command:

```bash
python3 -m venv <path_to_your_venv> --system-site-packages
```

After creating the virtual environment, activate it and install the required Python dependencies using pip:

```bash
source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>/src/autopilot_neural_network

pip install -r requirements.txt
```

### 🛠️ Build

Source the ROS 2 environment and the Python virtual environment, then build the package:

```bash
source /opt/ros/jazzy/setup.bash

source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>

colcon build
```

After a successful build, the system is ready to be used.

### 🚀 Usage

The sections below provide a description of how to use the project when running directly on a Linux system. They cover data collection, model training, and inference.

#### 📁 Data Collection

To launch the simulation for data collection, first set the `dataset_path` parameter in `autopilot_neural_network/config/parameters.yaml` to the desired data location and rebuild the workspace to apply the changes. 

Next, start the `gazebo_data_collection` launch file with the desired track through the `world` argument. Available tracks include `dirt_track`, `snow_track`, `sand_track`, and `grass_track`. The vehicle’s initial pose in the simulation can also be configured using the `x`, `y`, and `z` position arguments, along with the orientation arguments `R` (roll), `P` (pitch), and `Y` (yaw).

With the environment properly set up, you can launch the data collection simulation using the following command:

```bash
source /opt/ros/jazzy/setup.bash 

source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>

source install/setup.bash 

ros2 launch gazebo_autonomous_driving gazebo_data_collector.launch.py \
  world:=$(ros2 pkg prefix gazebo_racing_tracks)/share/gazebo_racing_tracks/worlds/dirt_track.sdf \
  x:=1.6 y:=3.0 z:=0.5 R:=0.0 P:=0.0 Y:=1.57
```

Once the launch file is running and an Xbox One joystick controller is connected to the computer, you can manually drive the vehicle inside the simulation. The system will then begin recording driving data according to the configured parameters, creating a dataset that can later be used to train the neural network.

#### 📉 Neural Network Training

Start the training process by activating the Python virtual environment and running the training script. The `dataset_path` argument must point to the directory where the collected dataset is stored, while the `model_path` argument defines where the trained model checkpoint will be saved:

```bash
source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>/src/autopilot_neural_network/scripts/

python3 train.py --dataset_path <path_to_your_dataset> \
                 --model_path <path_to_your_model>
```

If you want to monitor the training process, you can run [TensorBoard](https://www.tensorflow.org/tensorboard) in another shell while the model is training. Once it is running, open a web browser and access it at `http://localhost:6006/` to view the training dashboards:

```bash
source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>/src/autopilot_neural_network/scripts/

tensorboard --logdir=runs
```

#### 🚗 Inference

Ensure the correct model path is configured before starting the autopilot node. Set the `model_path` parameter in `autopilot_neural_network/config/parameters.yaml` to the location of the trained model, then rebuild the workspace so the changes take effect.

Next, to launch the simulation for autopilot control, set up the environment and start the `gazebo_autopilot` launch file with the desired track. Available tracks include `dirt_track`, `snow_track`, `sand_track`, and `grass_track`. You can also configure the vehicle’s initial pose in the simulation using the `x`, `y`, and `z` position arguments, along with the orientation arguments `R` (roll), `P` (pitch), and `Y` (yaw):

```bash
source /opt/ros/jazzy/setup.bash 

source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>

source install/setup.bash 

ros2 launch gazebo_autonomous_driving gazebo_autopilot.launch.py \
  world:=$(ros2 pkg prefix gazebo_racing_tracks)/share/gazebo_racing_tracks/worlds/grass_track.sdf \
  x:=1.0 y:=1.0 z:=0.5 R:=0.0 P:=0.0 Y:=0.0
```

If everything is set up correctly, the model will start driving the car autonomously.

## 🐳 Docker Setup

If you prefer not to set up the project directly on the Linux system, you can use **[Docker](https://www.docker.com/)** instead. Make sure Docker is properly installed and running on your machine before proceeding with the build and execution steps.

### 🛠️ Build

To simplify the setup, a helper script is provided to build the Docker image. Navigate to the project directory and run the `build_docker.sh` script:

```bash
cd gazebo_autonomous_driving

./build_docker.sh
```

### 🏃 Run

A helper script is also available to start the Docker container and enter the runtime environment. The `run_docker.sh` script automatically configures the required Docker volumes by mounting the `~/autopilot_neural_network` directory from the host into the container, making it available for storing the dataset and trained model files.

If you prefer to use a different directory on the host, you can modify the volume mount paths directly in the script. But, for a quick setup, simply create the `~/autopilot_neural_network` directory on the host machine and run the `run_docker.sh` script from the project directory:

```bash
mkdir ~/autopilot_neural_network

cd gazebo_autonomous_driving

./run_docker.sh
```

When this script is executed, it starts the container and opens an interactive shell inside the container. From this, you can follow the next steps in the Usage section to collect the dataset, train the model, or run inference.

### 🚀 Usage

The following sections describe how to use the project inside the Docker environment. These steps focus on running data collection, training, and inference directly from within the container, with datasets and models stored on the host through mounted volumes.

#### 📁 Data Collection

To launch the simulation for data collection, start the `gazebo_data_collection` launch file with the desired track through the `world` argument. Available tracks include `dirt_track`, `snow_track`, `sand_track`, and `grass_track`. The vehicle’s initial pose in the simulation can also be configured using the `x`, `y`, and `z` position arguments, along with the orientation arguments `R` (roll), `P` (pitch), and `Y` (yaw):

```bash
ros2 launch gazebo_autonomous_driving gazebo_data_collector.launch.py \
  world:=$(ros2 pkg prefix gazebo_racing_tracks)/share/gazebo_racing_tracks/worlds/dirt_track.sdf \
  x:=1.6 y:=3.0 z:=0.5 R:=0.0 P:=0.0 Y:=1.57
```
Once the launch file is running and an Xbox One joystick controller is connected to the computer, you can manually drive the vehicle inside the simulation. The dataset will be stored in the `~/autopilot_neural_network` directory on the host machine.

#### 📉 Neural Network Training

Access the `autopilot_neural_network/scripts` directory located at `~/workspace/src/` inside the container and run the `train.py` script from there to start the training process:

```bash
cd ~/workspace/src/autopilot_neural_network/scripts/

python3 train.py
```

If you want to monitor the training process, you can run [TensorBoard](https://www.tensorflow.org/tensorboard) in another shell inside the container while the model is training. Once it is running, open a web browser and access it at `http://localhost:6006/` to view the training dashboards:

```bash
cd ~/workspace/src/autopilot_neural_network/scripts/

tensorboard --logdir=runs
```

#### 🚗 Inference

The trained model must be named `model.pt` and placed inside the `~/autopilot_neural_network` directory on the host machine. This directory is mounted as a volume, allowing the container to access and load the model during execution. 

Next, to launch the simulation for autopilot control, start the `gazebo_autopilot` launch file with the desired track. Available tracks include `dirt_track`, `snow_track`, `sand_track`, and `grass_track`. You can also configure the vehicle’s initial pose in the simulation using the `x`, `y`, and `z` position arguments, along with the orientation arguments `R` (roll), `P` (pitch), and `Y` (yaw):

```bash
ros2 launch gazebo_autonomous_driving gazebo_autopilot.launch.py \
  world:=$(ros2 pkg prefix gazebo_racing_tracks)/share/gazebo_racing_tracks/worlds/grass_track.sdf \
  x:=1.0 y:=1.0 z:=0.5 R:=0.0 P:=0.0 Y:=0.0
```

If everything is set up correctly, the model will start driving the car autonomously.

## 🔧 Configuration

This section describes the available configuration options for the project, including training hyperparameters, vehicle settings, and other parameters. These options allow you to customize the learning process, simulation behavior, and data handling for your specific use case.

### ⚙️ Training Hyperparameters

The following arguments can be used with the `train.py` script to configure the training process:

- `--dataset_path`: Path to the directory containing the training dataset.

- `--model_path`: Path where the best trained model checkpoint will be saved.

- `--epochs`: Number of training epochs to run (default: 100).

- `--batch_size`: Batch size used for the training data loader (default: 1024).

- `--val_batch_size`: Batch size used for the validation data loader (default: 256).

- `--val_fraction`: Fraction of the dataset reserved for validation (e.g., 0.2 uses 20% of the data for validation).

- `--learning_rate`: Initial learning rate used by the optimizer  (default: 1e-3).

- `--lr_patience`: Number of epochs without validation loss improvement before reducing the learning rate.

- `--lr_factor`: Factor by which the learning rate is reduced when a plateau is detected.

- `--alpha`: Weight applied to the velocity component of the loss function.

- `--beta`: Weight applied to the steering angle component of the loss function.

- `--num_workers`: Number of worker processes used for loading data (default: number of CPU cores minus one).

- `--height`: Target height for resizing input images (default: 96 pixels).

- `--width`: Target width for resizing input images (default: 128 pixels).

- `--sampler_low_fraction`: Fraction of low-steering samples retained during dataset balancing.

- `--sampler_threshold_ratio`: Steering ratio (relative to maximum steering) used to define the low-steering region.

### ⚙️ Node Parameters

The parameters for the vehicle model, control, and camera can be configured in the ```gazebo_ackermann_steering_vehicle/config/parameters.yaml``` file. This file includes the following settings with their default values for the simulation:

```yaml
# Body params
body_length: 0.3 # Length of the vehicle's body [m]
body_width: 0.18 # Width of the vehicle's body [m]
body_height: 0.05 # Height of the vehicle's body [m]
body_density: 7850.0 # Density of the vehicle's body material, e.g., steel [kg/m^3]

# Wheel params
wheel_radius: 0.04 # Radius of each wheel [m]
wheel_width: 0.02 # Width of each wheel [m]
wheel_density: 900.0 # Density of the wheel material, e.g., rubber [kg/m^3]

# Kinematics and dynamics params
max_steering_angle: 0.6108652 # Maximum steering angle of the vehicle [rad]
max_steering_angular_velocity: 1.570796 # Maximum steering angular velocity [rad/s]
max_steering_effort: 1.0 # Maximum steering torque [Nm]
max_velocity: 2.0 # Maximum wheel velocity [m/s]
max_effort: 10.0 # Maximum wheel torque [Nm]

# Camera and image params
camera_box_size: 0.05 # Size of the camera enclosure [m]
camera_stick_size: 0.02 # Size of the camera stick [m]
camera_height: 0.2 # Height of the camera above the body_link [m]
camera_pitch: 0.698131 # Pitch angle of the camera relative to body_link [rad]
camera_fov: 1.3962634 # Field of view of the camera [rad]
camera_fps: 30 # Frames per second for camera capture [Hz]
image_width: 640 # Width of the camera's image output [pixels]
image_height: 480 # Height of the camera's image output [pixels]
```

The parameters for the data collection and inference nodes can be configured in the `autopilot_neural_network/config/parameters.yaml` file. This file includes the following settings with their default values:

```yaml
# Vehicle node and topics
vehicle_node: "vehicle_controller" # Name of the node from which to retrieve vehicle parameters
velocity_topic: "/velocity" # Topic for publishing/subscribing to velocity commands
steering_angle_topic: "/steering_angle" # Topic for publishing/subscribing to steering commands
image_topic: "/camera/image_raw" # Topic for subscribing to raw camera images

# Data Collector Node Parameters
collector_min_velocity_factor: 0.25 # Fraction of max velocity below which data is not recorded
collector_timeout_time: 1000000000 # Timeout for data freshness in nanoseconds [ns]
collector_update_period: 0.5 # Period for the node's update loop in seconds [s]

# Autopilot (Inference) Node Parameters
image_height: 96 # Height of the image for model input [px] 
image_width: 128 # Width of the image for model input [px] 

# File Paths
dataset_path: "/tmp/autopilot_neural_network/dataset" # Path where dataset is saved and loaded
model_path: "/tmp/autopilot_neural_network/model.pt" # Path to the trained model for inference
```
