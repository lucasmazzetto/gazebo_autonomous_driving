# Use the full desktop ROS 2 Jazzy image as the base (includes GUI tools, Rviz, etc.)
FROM osrf/ros:jazzy-desktop-full

ARG DISTRO=jazzy

# Update the package list and install essential ROS 2 packages and dependencies
RUN apt-get update 
RUN apt-get install -y \
    ros-${DISTRO}-ros2-controllers \
    ros-${DISTRO}-ros2-control \
    ros-${DISTRO}-gz-ros2-control \
    ros-${DISTRO}-ros-gz \
    ros-${DISTRO}-ros-gz-bridge \
    ros-${DISTRO}-joint-state-publisher \
    ros-${DISTRO}-robot-state-publisher \
    ros-${DISTRO}-xacro \
    ros-${DISTRO}-joy \
    curl \
    lsb-release \
    gnupg \
    python3 \   
    python3-venv \
    python3-pip \
    && apt-get clean

# Download and store the GPG key for Gazebo packages
RUN curl https://packages.osrfoundation.org/gazebo.gpg \
    --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg 

# Add the Gazebo package repository to APT sources
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable \
    $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# Update APT and install the Gazebo Harmonic release (GZ Harmonic)
RUN apt-get update 
RUN apt-get install -y gz-harmonic
RUN apt-get update
RUN apt-get upgrade -y

# Add a non-root user for safety and development convenience
ARG USERNAME=docker
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN if id -u ${USER_UID} ; then \
    userdel `id -un ${USER_UID}` ; fi

# Create the user group and user with home directory
RUN groupadd --gid ${USER_GID} ${USERNAME} 
RUN useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    apt-get update && \
    apt-get install -y sudo && \
    echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Set environment variables and switch to the new user
ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}
USER ${USERNAME}

# Define workspace name and set it as the working directory
ARG WORKSPACE=workspace
RUN mkdir -p ~/${WORKSPACE}/src/
WORKDIR /home/${USERNAME}/${WORKSPACE}

# Add user to common video/rendering-related groups to access GPU devices
RUN sudo groupadd -f render && \
    sudo groupadd -f avahi && \
    sudo groupadd -f video && \
    sudo usermod -a -G render,avahi,video ${USERNAME}

# Copy project source code into the Docker container
COPY ./autopilot_neural_network /home/${USERNAME}/${WORKSPACE}/src/autopilot_neural_network
COPY ./gazebo_ackermann_steering_vehicle /home/${USERNAME}/${WORKSPACE}/src/gazebo_ackermann_steering_vehicle
COPY ./gazebo_autonomous_driving /home/${USERNAME}/${WORKSPACE}/src/gazebo_autonomous_driving
COPY ./gazebo_racing_tracks /home/${USERNAME}/${WORKSPACE}/src/gazebo_racing_tracks

# Source the ROS 2 setup script automatically when the user opens a shell
RUN echo "source /opt/ros/${DISTRO}/setup.bash" >> ~/.bashrc

# Create Python virtual environment in the user's home directory    
RUN python3 -m venv /home/${USERNAME}/.venv --system-site-packages

RUN /home/${USERNAME}/.venv/bin/python -m pip install --upgrade pip && \
    /home/${USERNAME}/.venv/bin/python -m pip install \
        -r /home/${USERNAME}/${WORKSPACE}/src/autopilot_neural_network/requirements.txt

# # Build the workspace using colcon
RUN bash -c "source /opt/ros/${DISTRO}/setup.bash && \
             source /home/${USERNAME}/.venv/bin/activate && \ 
             colcon build"

# Activate Python virtual environment if it exists
RUN echo "if [ -f /home/${USERNAME}/.venv/bin/activate ]; then \
    source /home/${USERNAME}/.venv/bin/activate; fi" >> /home/${USERNAME}/.bashrc

# Source the workspace’s install/setup.bash if it exists (build system output)
RUN echo "if [ -f /home/${USERNAME}/${WORKSPACE}/install/setup.bash ]; then \
    source /home/${USERNAME}/${WORKSPACE}/install/setup.bash; fi" >> /home/${USERNAME}/.bashrc

# Set the GZ simulation plugin path for runtime
RUN echo "export GZ_SIM_SYSTEM_PLUGIN_PATH=/opt/ros/${DISTRO}/lib/:/usr/lib:/usr/lib/x86_64-linux-gnu" >> ~/.bashrc