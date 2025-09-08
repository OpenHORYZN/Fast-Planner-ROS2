cmake_minimum_required(VERSION 3.10)
project(plan_manage)

# C++ standard
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build flags
add_compile_options(-O3 -Wall)

# Find dependencies
find_package(ament_cmake REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(PCL REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(plan_env REQUIRED)
find_package(path_searching REQUIRED)
find_package(bspline REQUIRED)
find_package(bspline_opt REQUIRED)
find_package(traj_utils REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(plan_manage_msgs REQUIRED)
find_package(mavros_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_sensor_msgs REQUIRED)

find_package(OpenMP)

find_package(PCL REQUIRED COMPONENTS common io)
find_package(pcl_conversions REQUIRED)

# Enable CUDA language if available


# Find CUDA toolkit
if(USE_GPU)
    find_package(CUDAToolkit QUIET)
    enable_language(CUDA OPTIONAL)
endif()


if(CMAKE_CUDA_COMPILER AND CUDAToolkit_FOUND)
    list(APPEND PLAN_ENV_SOURCES src/cuda_sdf_map.cu)
    add_compile_definitions(USE_CUDA)
    message(STATUS "CUDA found - building with GPU acceleration")
else()
    message(STATUS "CUDA not found - building CPU-only version")
endif()

# Define common dependencies
set(PLAN_MANAGE_DEPENDENCIES
  rclcpp
  std_msgs
  geometry_msgs
  plan_env
  path_searching
  bspline
  bspline_opt
  traj_utils
  cv_bridge
  Eigen3
  PCL
  plan_manage_msgs
  tf2
  tf2_ros
  tf2_sensor_msgs
  mavros_msgs
)

# fast_planner_node executable
add_executable(fast_planner_node
  src/fast_planner_node.cpp
  src/kino_replan_fsm.cpp
  src/topo_replan_fsm.cpp
  src/planner_manager.cpp
)

target_include_directories(fast_planner_node
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

ament_target_dependencies(fast_planner_node ${PLAN_MANAGE_DEPENDENCIES})

target_link_libraries(fast_planner_node
  plan_env::plan_env
  bspline::bspline
  bspline_opt::bspline_opt
  path_searching::path_searching
  traj_utils::traj_utils
)

#point cloud merge executable

add_executable(point_merge
  src/point_cloud_merge.cpp
)

target_include_directories(point_merge
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

ament_target_dependencies(point_merge ${PLAN_MANAGE_DEPENDENCIES} pcl_conversions)

target_link_libraries(point_merge
  ${PCL_LIBRARIES}
)

# point_utils executable
add_executable(point_utils
  src/point_utils.cpp
)

target_include_directories(point_utils
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

ament_target_dependencies(point_utils ${PLAN_MANAGE_DEPENDENCIES})

target_link_libraries(point_utils
  bspline::bspline
  bspline_opt::bspline_opt
  path_searching::path_searching
  traj_utils::traj_utils
)

# traj_server executable
add_executable(traj_server
  src/traj_server.cpp
)

target_include_directories(traj_server
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

ament_target_dependencies(traj_server ${PLAN_MANAGE_DEPENDENCIES})

target_link_libraries(traj_server
  bspline::bspline
  bspline_opt::bspline_opt
  path_searching::path_searching
  traj_utils::traj_utils
)

# Install targets
install(TARGETS
  fast_planner_node
  traj_server
  point_utils
  point_merge
  DESTINATION lib/${PROJECT_NAME}
)

# Install public headers
install(DIRECTORY include/
  DESTINATION include
)

# Export for downstream packages
ament_export_include_directories(include)
ament_export_dependencies(${PLAN_MANAGE_DEPENDENCIES})

install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)

# Finalize
ament_package()