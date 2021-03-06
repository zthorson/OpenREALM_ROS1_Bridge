#!/bin/bash
set -ex

# Update the Apt Cache
sudo apt update

# Catkin tools for build process
sudo apt install -y -q python-catkin-tools build-essential git wget

# Check CMake version and update if necessary
OUTPUT=$(cmake --version)
read CMAKE_VERSION_MAJOR CMAKE_VERSION_MINOR CMAKE_VERSION_PATCH <<< ${OUTPUT//[^0-9]/ }
if [ "${CMAKE_VERSION_MINOR}" -le 9 ]; then

  echo 'CMake Version is too old! Trying to download newer version '
  cd ~

  CMAKE_FILE="cmake-3.10.3-Linux-x86_64"

  # Check if file already exists
  if [ ! -e "${CMAKE_FILE}.tar.gz" ]; then
    sudo wget https://cmake.org/files/v3.10/${CMAKE_FILE}.tar.gz
  fi

  # Remove existing unpacked cmake folder
  if [ -d "${CMAKE_FILE}" ]; then
    sudo rm -r ${CMAKE_FILE}
  fi

  sudo tar xvzf ${CMAKE_FILE}.tar.gz

  export PATH="`pwd`/${CMAKE_FILE}/bin:$PATH"
fi

# Additional ROS package dependencies
sudo apt install -y -q ros-$ROS_DISTRO-geographic-msgs
sudo apt install -y -q ros-$ROS_DISTRO-geodesy
sudo apt install -y -q ros-$ROS_DISTRO-cv-bridge
sudo apt install -y -q ros-$ROS_DISTRO-rviz
sudo apt install -y -q ros-$ROS_DISTRO-pcl-ros

# Install specific opencv version for openvslam
cd ~ && git clone -b 3.3.1 https://github.com/opencv/opencv.git \
&& cd ~/opencv && mkdir build && cd build \
&& cmake -D CMAKE_BUILD_TYPE=RELEASE -D BUILD_EXAMPLES=OFF -D BUILD_opencv_apps=OFF -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. \
&& make && sudo make install

# Finally install OpenREALM Librararies
cd ~ && mkdir OpenREALM && cd OpenREALM
git clone https://github.com/laxnpander/OpenREALM.git
cd OpenREALM && OPEN_REALM_DIR=$(pwd)

if [ "$TRAVIS_BRANCH" = "dev" ]; then
	echo "Detected git branch: '${GIT_BRANCH}'. Checking out OpenREALM dev..."
	git checkout dev
else
	echo "Detected git branch: '${GIT_BRANCH}'. Continue OpenREALM library as master."
fi

cd tools && source install_deps.sh -i

cd $OPEN_REALM_DIR && mkdir build && cd build && cmake -DTESTS_ENABLED=ON ..
make -j $(nproc --all) && make install
