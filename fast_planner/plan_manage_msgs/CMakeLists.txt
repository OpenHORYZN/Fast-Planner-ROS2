cmake_minimum_required(VERSION 3.8)
project(plan_manage_msgs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(std_msgs REQUIRED)

# Message generation
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Bspline.msg"
  DEPENDENCIES std_msgs geometry_msgs builtin_interfaces
)

ament_export_dependencies(rosidl_default_runtime)

# Install msg folder for introspection tools
install(DIRECTORY msg
  DESTINATION share/${PROJECT_NAME}
)

ament_package()