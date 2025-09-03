cmake_minimum_required(VERSION 3.5)
project(bspline_opt)

# C++ Standard and Build Type
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

# Force Release flags (optional)
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  add_compile_options(-O3 -Wall)
endif()

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(plan_env REQUIRED)

find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)

# Manually find NLOPT (since it's not a ROS 2 package)
set(NLOPT_INCLUDE_DIR "/usr/local/include")
set(NLOPT_LIBRARY "/usr/local/lib/libnlopt.so")

# Build the library
add_library(bspline_opt
  src/bspline_optimizer.cpp
)

# Include directories
target_include_directories(bspline_opt
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/${PROJECT_NAME}>
    ${Eigen3_INCLUDE_DIRS}
    ${PCL_INCLUDE_DIRS}
    ${NLOPT_INCLUDE_DIR}
)

# Link dependencies
ament_target_dependencies(bspline_opt
  rclcpp
  std_msgs
  visualization_msgs
  cv_bridge
  plan_env
)

target_link_libraries(bspline_opt
  ${PCL_LIBRARIES}
  ${NLOPT_LIBRARY}
)

install(
  DIRECTORY include/
  DESTINATION include/${PROJECT_NAME}
)

# Install targets
install(TARGETS bspline_opt
  EXPORT export_bspline_opt
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# Install headers
# install(DIRECTORY include/
#   DESTINATION include
# )

# Export the library
ament_export_targets(export_bspline_opt HAS_LIBRARY_TARGET)
ament_export_dependencies(
  rclcpp
  std_msgs
  visualization_msgs
  cv_bridge
  plan_env
)

ament_export_include_directories(include)

ament_export_libraries(bspline_opt)

# Finalize
ament_package()