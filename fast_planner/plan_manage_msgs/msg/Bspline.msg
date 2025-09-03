# plan_manage/msg/TrajInfo.msg

int32 order
int64 traj_id

# use the ROS2 builtin_interfaces/Time for timestamps
builtin_interfaces/Time start_time

float64[] knots
geometry_msgs/Point[] pos_pts

float64[] yaw_pts
float64 yaw_dt