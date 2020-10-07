########## Pull ##########
FROM ros:kinetic
# FROM osrf/ros:kinetic-desktop-full
########## nvidia-docker1 hooks ##########
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
########## Basis ##########
RUN apt-get update && apt-get install -y \
	vim \
	wget \
	unzip \
	git \
	build-essential
########## ROS setup ##########
RUN mkdir -p /home/ros_catkin_ws/src && \
	cd /home/ros_catkin_ws/src && \
	/bin/bash -c "source /opt/ros/kinetic/setup.bash; catkin_init_workspace" && \
	cd /home/ros_catkin_ws && \
	/bin/bash -c "source /opt/ros/kinetic/setup.bash; catkin_make" && \
	echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc && \
	echo "source /home/ros_catkin_ws/devel/setup.bash" >> ~/.bashrc && \
	echo "export ROS_PACKAGE_PATH=\${ROS_PACKAGE_PATH}:/home/ros_catkin_ws" >> ~/.bashrc && \
	echo "export ROS_WORKSPACE=/home/ros_catkin_ws" >> ~/.bashrc && \
	echo "function cmk(){\n	lastpwd=\$OLDPWD \n	cpath=\$(pwd) \n	cd /home/ros_catkin_ws \n	catkin_make \$@ \n	cd \$cpath \n	OLDPWD=\$lastpwd \n}" >> ~/.bashrc
########## ROS packages requirements ##########
RUN apt-get update && apt-get install -y \
		ros-kinetic-roslint \
		ros-kinetic-cv-bridge \
		ros-kinetic-pcl-ros \
		ros-kinetic-image-transport \
		ros-kinetic-image-geometry \
		ros-kinetic-eigen-conversions \
		ros-kinetic-costmap-2d \
		ros-kinetic-camera-info-manager \
		ros-kinetic-velodyne-pointcloud
########## PCL 1.8 ##########
RUN apt-get update && apt-get install -y libpcl-dev
########## Eigen 3.1.0 ##########
## https://gitlab.com/libeigen/eigen/-/releases
RUN	mkdir -p /home/eigen_ws &&\
	cd /home/eigen_ws &&\
	wget https://gitlab.com/libeigen/eigen/-/archive/3.1.0/eigen-3.1.0.zip &&\
	unzip eigen-3.1.0.zip &&\
	cd eigen-3.1.0 && \
	mkdir build &&\
	cd build &&\
	cmake .. &&\
	make -j $(nproc --all) &&\
	make install
# ########## OpenCV 2.4.9 ##########
# ## https://opencv.org/releases/
# RUN apt-get update && apt-get install -y qtbase5-dev &&\
# 	mkdir -p /home/opencv_ws &&\
# 	cd /home/opencv_ws &&\
# 	wget https://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.9/opencv-2.4.9.zip/download &&\
# 	unzip download &&\
# 	cd opencv-2.4.9 &&\
# 	mkdir build &&\
# 	cd build &&\
# 	cmake -D WITH_TBB=ON -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON -D INSTALL_C_EXAMPLES=ON -D INSTALL_PYTHON_EXAMPLES=ON -D BUILD_EXAMPLES=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_VTK=ON .. &&\
# 	make -j $(nproc --all) &&\
# 	make install
########## but_velodyne_lib ##########
RUN cd /home &&\
	git clone https://github.com/robofit/but_velodyne_lib &&\
	cd but_velodyne_lib &&\
	mkdir build &&\
	cd build &&\
	cmake .. &&\
	make -j $(nproc --all) &&\
	make install
########## but_velodyne ##########
## http://wiki.ros.org/but_velodyne
RUN cd /home/ros_catkin_ws/src &&\
	git clone https://github.com/robofit/but_velodyne &&\
	sed -i 's/cv::vector/std::vector/g' /usr/local/include/but_velodyne-0.1/but_velodyne/Visualizer3D.h &&\
	sed -i '1s/^/#include "opencv2\/video\/tracking.hpp"\n/' /usr/local/include/but_velodyne-0.1/but_velodyne/MoveEstimation.h &&\
	cd /home/ros_catkin_ws && \
	/bin/bash -c "source /opt/ros/kinetic/setup.bash; catkin_make"
######### initial position ##########
WORKDIR /home/ros_catkin_ws
