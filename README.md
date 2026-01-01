# Gazebo Autonomous Driving

## 🚗 About

This repository provides a autonomous driving simulation environment built with ROS 2 Jazzy Jalisco and Gazebo Harmonic, combining a vehicle simulation, simulated racing tracks, and an autopilot package.

## 💻 Instalation


Clone this repository into your computer using ```--recurse-submodules```, as the project relies on Git submodules.

```bash
git clone --recurse-submodules git@github.com:lucasmazzetto/gazebo_autonomous_driving.git
```

After cloning, move all the contents of the repository into the ROS 2 ```workspace/src``` directory. If you don't have a workspace set up, you can learn more about creating one in the [ROS 2 workspace tutorial](https://docs.ros.org/en/jazzy/Tutorials/Beginner-Client-Libraries/Creating-A-Workspace/Creating-A-Workspace.html).

```bash
mv gazebo_autonomous_driving/* <path_to_your_workspace>/src
```

### 🐧 Linux Setup

This project is designed to run on Linux Ubuntu 24.04 and may also work on other Linux versions or distributions, although additional adjustments might be required. 

#### 📚 Requirements

To use this package, you'll need the following:

- [Linux Ubuntu 24.04](https://ubuntu.com/blog/tag/ubuntu-24-04-lts)
- [ROS2 Jazzy Jalisco](https://docs.ros.org/en/rolling/Releases/Release-Jazzy-Jalisco.html)
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

#### 🛠️ Build

Source the ROS 2 environment and the Python virtual environment, then build the package:

```bash
source /opt/ros/jazzy/setup.bash

source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>

colcon build
```

After a successful build, the system is ready to be used.

### 🐳 Docker Setup

If you prefer not to set up the project directly on your Linux system, you can use **[Docker](https://www.docker.com/)** instead. It ensures a consistent environment and simplifies dependency management across different systems. Make sure Docker is properly installed and running on your machine before proceeding with the build and execution steps.


#### 🛠️ Build

To simplify the setup, a helper script is provided to build the Docker image. Navigate to the project directory and run the ./`build_docker.sh` script:

```bash
cd <path_to_the_project_directory>

./build_docker.sh
```

#### 🏃 Run

To run the project, it is necessary to configure Docker volumes for both the dataset directory and the trained model file. This can be done by creating a folder named `autopilot_neural_network` in your home directory, which will be mounted automatically, or by manually editing the `run_docker.sh` script to adjust the volume paths as needed.

In summary, for a quick setup:

```bash
mkdir ~/autopilot_neural_network

cd <path_to_the_project_directory>

./run_docker.sh
```

When this script is executed, it starts the container and opens an interactive shell inside the Docker environment. From this shell, you can follow the next steps in the Usage section to collect the dataset, train the model, or run inference.

However, no changes are required in `autopilot_neural_network/config/parameters.yaml` regarding the model path or the dataset directory. The Docker setup is already configured to use `/tmp/autopilot_neural_network/model.pt` for the model file and `/tmp/autopilot_neural_network/dataset` for the dataset, which are properly mapped to the host through Docker volumes.

## 🚀 Usage

### 🗂️ Data Collection

Before collecting data, configure where the dataset will be stored. Update the `dataset_path` parameter in the `autopilot_neural_network/config/parameters.yaml` file to point to your desired dataset destination. Make sure to rebuild the system after changing the parameters.

Then, to launch the simulation for data collection, set up the environment and start the `gazebo_data_collection` node with the desired track. Available tracks include `dirt_track`, `snow_track`, `grass_track`,`sand_track`, and `grass_track`:

```bash
source /opt/ros/jazzy/setup.bash 

source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>

source install/setup.bash 

ros2 launch gazebo_autonomous_driving gazebo_data_collector.launch.py \
  world:=$(ros2 pkg prefix gazebo_racing_tracks)/share/gazebo_racing_tracks/worlds/dirt_track.sdf \
  x:=1.6 y:=3.0 z:=0.5 R:=0.0 P:=0.0 Y:=1.57
```

### 📉 Neural Network Training

To start the training process, activate the Python virtual environment and run the training script with the dataset and model paths specified:

```bash
source <path_to_your_venv>/bin/activate

cd <path_to_your_workspace>/src/autopilot_neural_network/scripts/

python3 train.py --dataset_path <path_to_your_dataset> \
                 --model_path <path_to_your_model>
```

The following arguments can be used with the `train.py` script to configure the training process:

- --`dataset_path`: Path to the directory containing the training dataset.

- --`model_path`: Path where the best trained model checkpoint will be saved.

- --`epochs`: Number of training epochs to run (default: 100).

- --`batch_size`: Batch size used for the training data loader (default: 1024).

- --`val_batch_size`: Batch size used for the validation data loader (default: 256).

- --`val_fraction`: Fraction of the dataset reserved for validation (e.g., 0.2 uses 20% of the data for validation).

- --`learning_rate`: Initial learning rate used by the optimizer  (default: 1e-3).

- --`lr_patience`: Number of epochs without validation loss improvement before reducing the learning rate.

- --`lr_factor`: Factor by which the learning rate is reduced when a plateau is detected.

- --`alpha`: Weight applied to the velocity component of the loss function.

- --`beta`: Weight applied to the steering angle component of the loss function.

- --`num_workers`: Number of worker processes used for loading data (default: number of CPU cores minus one).

- --`height`: Target height for resizing input images (default: 96 pixels).

- --`width`: Target width for resizing input images (default: 128 pixels).

- --`sampler_low_fraction`: Fraction of low-steering samples retained during dataset balancing.

- --`sampler_threshold_ratio`: Steering ratio (relative to maximum steering) used to define the low-steering region.

### 🚗 Inference

Before starting the `autopilot` node, make sure the correct model is configured. Update the `model_path` parameter in the `autopilot_neural_network/config/parameters.yaml` file to point to the location of your trained model. This ensures that the autopilot loads and uses the intended neural network during execution. Make sure to rebuild the system after changing the parameters.

Then, to launch the simulation for autopilot control, set up the environment and start the `gazebo_autopilot` node with the desired track.

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

## ⚙️ Parameters

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

The parameters for the data colection and inference nodes can be configured in the `autopilot_neural_network/config/parameters.yaml` file. This file includes the following settings with their default values:

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