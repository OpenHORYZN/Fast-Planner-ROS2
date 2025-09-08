cmake_minimum_required(VERSION 3.8)
project(plan_env)

# --------------------------
# C++ standard
# --------------------------
if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 17)
endif()

# --------------------------
# Option to force CPU build
# --------------------------
option(USE_GPU "Build with CUDA GPU acceleration" ON)

# Enable CUDA if GPU is requested
if(USE_GPU)
    enable_language(CUDA OPTIONAL)
endif()

# --------------------------
# Find dependencies
# --------------------------
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(message_filters REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(pcl_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(OpenMP)

# Find CUDA toolkit if GPU is requested
if(USE_GPU)
    find_package(CUDAToolkit QUIET)
endif()

# --------------------------
# Source files
# --------------------------
set(PLAN_ENV_SOURCES
    src/sdf_map.cpp
    src/obj_predictor.cpp
    src/edt_environment.cpp
    src/raycast.cpp
)

# Add CUDA source if GPU is enabled and found
if(USE_GPU AND CUDAToolkit_FOUND AND CMAKE_CUDA_COMPILER)
    list(APPEND PLAN_ENV_SOURCES src/cuda_sdf_map.cu)
    add_compile_definitions(USE_CUDA)
    message(STATUS "CUDA found - building with GPU acceleration")
else()
    message(STATUS "Building CPU-only version")
endif()

# --------------------------
# Library
# --------------------------
add_library(plan_env ${PLAN_ENV_SOURCES})

# Include directories
target_include_directories(plan_env
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
        ${Eigen3_INCLUDE_DIRS}
        ${PCL_INCLUDE_DIRS}
        ${OpenCV_INCLUDE_DIRS}
)

# Link PCL
target_link_libraries(plan_env ${PCL_LIBRARIES})

# Link CUDA if GPU enabled
if(USE_GPU AND CUDAToolkit_FOUND AND CMAKE_CUDA_COMPILER)
    set_target_properties(plan_env PROPERTIES
        CUDA_RUNTIME_LIBRARY Static
        CUDA_ARCHITECTURES "60;70;75;80;86"
    )
    target_link_libraries(plan_env CUDA::cudart CUDA::cublas CUDA::curand)
endif()

# Link OpenMP if found
if(OpenMP_CXX_FOUND)
    target_link_libraries(plan_env OpenMP::OpenMP_CXX)
endif()

# ROS2 dependencies
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

# --------------------------
# Executable
# --------------------------
add_executable(obj_generator src/obj_generator.cpp)
target_include_directories(obj_generator PRIVATE include)
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
target_link_libraries(obj_generator plan_env)

# --------------------------
# Install rules
# --------------------------
install(TARGETS
    plan_env
    EXPORT export_plan_env
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(TARGETS obj_generator DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)

# --------------------------
# Export
# --------------------------
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

# --------------------------
# Finalize
# --------------------------
ament_package()
