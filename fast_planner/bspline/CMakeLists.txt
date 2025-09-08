cmake_minimum_required(VERSION 3.5)
project(bspline)

# C++ version
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
find_package(pcl_msgs REQUIRED)

find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)
find_package(OpenMP)

# Enable CUDA language if available
enable_language(CUDA OPTIONAL)

# Find CUDA toolkit
find_package(CUDAToolkit REQUIRED)


# Create library
add_library(bspline
  src/non_uniform_bspline.cpp
)

# Include directories
target_include_directories(bspline
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
    ${Eigen3_INCLUDE_DIRS}
    ${PCL_INCLUDE_DIRS}
)

# Compile flags (optional, add if you want)
target_compile_options(bspline PRIVATE -O3 -Wall -Wextra)

# Link dependencies
ament_target_dependencies(bspline
  rclcpp
  std_msgs
  pcl_msgs
  visualization_msgs
  plan_env
  cv_bridge
)

# PCL may still need linking manually
target_link_libraries(bspline
  ${PCL_LIBRARIES}
)

# Install targets and headers
install(TARGETS bspline
  EXPORT export_bspline
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY include/
  DESTINATION include
)

# Export for downstream packages
ament_export_dependencies(
  rclcpp
  std_msgs
  visualization_msgs
  plan_env
  pcl_msgs
  cv_bridge
)
ament_export_include_directories(include)

ament_export_targets(export_bspline)

# Finalize package
ament_package()