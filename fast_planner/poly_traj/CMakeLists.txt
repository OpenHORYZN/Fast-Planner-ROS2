cmake_minimum_required(VERSION 3.10)
project(poly_traj)

# C++ Standard
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(-O3 -Wall)

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(Eigen3 REQUIRED)  # This defines imported target: Eigen3::Eigen
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)


# Build the library
add_library(poly_traj
  src/polynomial_traj.cpp
)

# Correct way to add include directories
target_include_directories(poly_traj
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Link to Eigen3 IMPORTED target properly
target_link_libraries(poly_traj
  Eigen3::Eigen
)

# Link to ROS2 packages
ament_target_dependencies(poly_traj
  rclcpp
  std_msgs
  nav_msgs
  visualization_msgs
)

# Optional alias
add_library(${PROJECT_NAME}::poly_traj ALIAS poly_traj)

# Install targets
install(TARGETS poly_traj
  EXPORT export_poly_traj
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY include/
  DESTINATION include
)

# Export
ament_export_targets(export_poly_traj HAS_LIBRARY_TARGET)
ament_export_include_directories(include)
ament_export_dependencies(rclcpp std_msgs Eigen3 nav_msgs visualization_msgs)

ament_package()