cmake_minimum_required(VERSION 3.5)
project(plan_env)

# C++ version
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(message_filters REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)
find_package(pcl_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(OpenCV REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(nav_msgs REQUIRED)

# Build the shared library
add_library(plan_env
  src/sdf_map.cpp 
  src/obj_predictor.cpp 
  src/edt_environment.cpp 
  src/raycast.cpp
)

target_include_directories(plan_env
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
    ${Eigen3_INCLUDE_DIRS}
    ${PCL_INCLUDE_DIRS}
    ${OpenCV_INCLUDE_DIRS}
)

ament_target_dependencies(plan_env
  rclcpp
  std_msgs
  visualization_msgs
  cv_bridge
  message_filters
  pcl_msgs
  pcl_conversions
  nav_msgs
)

target_link_libraries(plan_env
  ${PCL_LIBRARIES}
)

# Build the executable
add_executable(obj_generator
  src/obj_generator.cpp
)

target_include_directories(obj_generator
  PRIVATE
    include
)

ament_target_dependencies(obj_generator
  rclcpp
  std_msgs
  visualization_msgs
  cv_bridge
  message_filters
  pcl_msgs
  pcl_conversions
  nav_msgs
)

# If obj_generator needs plan_env functionality
target_link_libraries(obj_generator
  plan_env
)

# Install library
install(TARGETS
  plan_env
  EXPORT export_plan_env
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# Install executable
install(TARGETS
  obj_generator
  DESTINATION lib/${PROJECT_NAME}
)

# Install headers
install(DIRECTORY include/
  DESTINATION include
)

# Export for other packages
ament_export_targets(export_plan_env)
ament_export_dependencies(
  rclcpp
  std_msgs
  visualization_msgs
  cv_bridge
  message_filters
  pcl_msgs
  pcl_conversions
  nav_msgs
)

ament_export_include_directories(include)

# Finalize
ament_package()