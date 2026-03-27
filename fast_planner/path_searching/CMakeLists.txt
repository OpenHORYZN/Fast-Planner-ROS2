cmake_minimum_required(VERSION 3.5)
project(path_searching)

# C++ Standard
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)

# Enable CUDA language if available
enable_language(CUDA OPTIONAL)

# Find CUDA toolkit
find_package(CUDAToolkit REQUIRED)
find_package(OpenMP REQUIRED)


# Create library
add_library(path_searching
  src/kinodynamic_astar.cpp
  src/astar.cpp
  src/topo_prm.cpp
)

# Include directories
target_include_directories(path_searching
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
    ${Eigen3_INCLUDE_DIRS}
    ${PCL_INCLUDE_DIRS}
)

# Link dependencies
ament_target_dependencies(path_searching
  rclcpp
  std_msgs
  visualization_msgs
  plan_env
  cv_bridge
)

target_link_libraries(path_searching
  ${PCL_LIBRARIES}
)

# Install the library
install(TARGETS
  path_searching
  EXPORT export_path_searching
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY include/
  DESTINATION include
)

# Export for other packages
ament_export_targets(export_path_searching)
ament_export_dependencies(
  rclcpp
  std_msgs
  visualization_msgs
  plan_env
  cv_bridge
)

ament_export_include_directories(include)

# Finalize
ament_package()