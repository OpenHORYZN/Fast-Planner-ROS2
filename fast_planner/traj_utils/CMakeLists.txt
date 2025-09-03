cmake_minimum_required(VERSION 3.10)
project(traj_utils)

# C++ Standard
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build flags
add_compile_options(-O3 -Wall -w)

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(path_searching REQUIRED)
find_package(poly_traj REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)

# Build the library
add_library(traj_utils
  src/planning_visualization.cpp
)

# Correct modern way to include headers
target_include_directories(traj_utils
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Link dependencies
ament_target_dependencies(traj_utils
  rclcpp
  std_msgs
  cv_bridge
  bspline
  bspline_opt
  path_searching
  poly_traj
  Eigen3
  PCL
)

# Optional alias
add_library(${PROJECT_NAME}::traj_utils ALIAS traj_utils)

# Install library
install(TARGETS traj_utils
  EXPORT export_traj_utils
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY include/
  DESTINATION include
)

# Export for downstream packages
ament_export_targets(export_traj_utils HAS_LIBRARY_TARGET)
ament_export_include_directories(include)
ament_export_dependencies(
  rclcpp
  std_msgs
  cv_bridge
  bspline
  bspline_opt
  path_searching
  poly_traj
  Eigen3
  PCL
)

# Finalize
ament_package()