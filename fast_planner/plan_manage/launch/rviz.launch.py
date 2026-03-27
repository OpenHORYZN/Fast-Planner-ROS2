from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    config_path = os.path.join(
        get_package_share_directory('plan_manage'),
        'config',
        'traj.rviz'
    )

    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rvizvisualisation',
        output='log',
        arguments=['-d', config_path]
    )

    return LaunchDescription([rviz_node])
