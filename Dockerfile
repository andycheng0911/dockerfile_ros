# 使用 Ubuntu 20.04 作為基底
FROM ubuntu:20.04

# 設定非互動模式，避免安裝過程中出現選項
ENV DEBIAN_FRONTEND=noninteractive

# 更新並安裝基本依賴
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    sudo \
    git \
    cmake \
    build-essential \
    ninja-build \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# 添加 ROS Noetic 套件源並安裝 ROS
RUN curl -sSL 'https://raw.githubusercontent.com/ros/rosdistro/master/ros.key' | apt-key add - && \
    echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-get update && apt-get install -y \
    ros-noetic-desktop-full \
    python3-catkin-pkg-modules \
    python3-rospkg-modules \
    python3-rosdistro-modules \
    python3-rosdep \
    python3-vcstool \
    && rm -rf /var/lib/apt/lists/*

# 初始化 rosdep
RUN rosdep init && rosdep update

# 設定 ROS 環境變數
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc
ENV ROS_PACKAGE_PATH=/opt/ros/noetic/share

# 下載 PX4 並安裝依賴
WORKDIR /opt
RUN git clone --branch v1.14.0 --recursive --depth=1 https://github.com/PX4/PX4-Autopilot.git 

# 切換到 PX4 目錄並執行安裝腳本
WORKDIR /opt/PX4-Autopilot
RUN chmod +x Tools/setup/ubuntu.sh && bash Tools/setup/ubuntu.sh

# 設定 PX4 環境變數
RUN echo "source /opt/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash /opt/PX4-Autopilot /opt/PX4-Autopilot/build/px4_sitl_default" >> /root/.bashrc && \
    echo "export PX4_SIM_MODEL=iris" >> /root/.bashrc && \
    echo "export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/opt/PX4-Autopilot" >> /root/.bashrc && \
    echo "export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/opt/PX4-Autopilot/Tools/sitl_gazebo" >> /root/.bashrc

# 確保掛載的工作空間能正確使用
RUN mkdir -p /my_ws/src

# 最後執行 bash，保持容器運行
CMD ["/bin/bash"]
