from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():

    # Main planner node
    fast_planner_node = Node(
        package='plan_manage',
        executable='fast_planner_node',
        name='fast_planner_node',
        output='screen',
        remappings=[
            ('/odom_world', '/state_ukf/odom'),
            ('/sdf_map/odom', '/state_ukf/odom'),
            ('/sdf_map/cloud', '/pcl_render_node/cloud'),
            ('/sdf_map/pose', '/pcl_render_node/camera_pose'),
            ('/sdf_map/depth', '/pcl_render_node/depth'),
        ],
        parameters=[{
            # Replanning method
            'planner_node/planner': 1,

            # FSM params
            'fsm/flight_type': 1,
            'fsm/thresh_replan': 1.5,
            'fsm/thresh_no_replan': 2.0,
            'fsm/waypoint_num': 2,
            'fsm/waypoint0_x': 19.0,
            'fsm/waypoint0_y': 0.0,
            'fsm/waypoint0_z': 1.0,
            'fsm/waypoint1_x': -19.0,
            'fsm/waypoint1_y': 0.0,
            'fsm/waypoint1_z': 1.0,
            'fsm/waypoint2_x': 0.0,
            'fsm/waypoint2_y': 19.0,
            'fsm/waypoint2_z': 1.0,

            # Map parameters
            'sdf_map/resolution': 0.1,
            'sdf_map/map_size_x': 40.0,
            'sdf_map/map_size_y': 20.0,
            'sdf_map/map_size_z': 5.0,
            'sdf_map/local_update_range_x': 5.5,
            'sdf_map/local_update_range_y': 5.5,
            'sdf_map/local_update_range_z': 4.5,
            'sdf_map/obstacles_inflation': 0.099,
            'sdf_map/local_bound_inflate': 0.0,
            'sdf_map/local_map_margin': 50,
            'sdf_map/ground_height': -1.0,
            'sdf_map/cx': 321.04638671875,
            'sdf_map/cy': 243.44969177246094,
            'sdf_map/fx': 387.229248046875,
            'sdf_map/fy': 387.229248046875,
            'sdf_map/use_depth_filter': True,
            'sdf_map/depth_filter_tolerance': 0.15,
            'sdf_map/depth_filter_maxdist': 5.0,
            'sdf_map/depth_filter_mindist': 0.2,
            'sdf_map/depth_filter_margin': 2,
            'sdf_map/k_depth_scaling_factor': 1000.0,
            'sdf_map/skip_pixel': 2,
            'sdf_map/p_hit': 0.65,
            'sdf_map/p_miss': 0.35,
            'sdf_map/p_min': 0.12,
            'sdf_map/p_max': 0.90,
            'sdf_map/p_occ': 0.80,
            'sdf_map/min_ray_length': 0.5,
            'sdf_map/max_ray_length': 4.5,
            'sdf_map/esdf_slice_height': 0.3,
            'sdf_map/visualization_truncate_height': 2.49,
            'sdf_map/virtual_ceil_height': 2.5,
            'sdf_map/show_occ_time': False,
            'sdf_map/show_esdf_time': False,
            'sdf_map/pose_type': 1,
            'sdf_map/frame_id': 'world',

            # Planner manager
            'manager/max_vel': 3.0,
            'manager/max_acc': 2.0,
            'manager/max_jerk': 4.0,
            'manager/dynamic_environment': 0,
            'manager/local_segment_length': 6.0,
            'manager/clearance_threshold': 0.2,
            'manager/control_points_distance': 0.5,
            'manager/use_geometric_path': False,
            'manager/use_kinodynamic_path': True,
            'manager/use_topo_path': False,
            'manager/use_optimization': True,

            # Kinodynamic search
            'search/max_tau': 0.6,
            'search/init_max_tau': 0.8,
            'search/max_vel': 3.0,
            'search/max_acc': 2.0,
            'search/w_time': 10.0,
            'search/horizon': 7.0,
            'search/lambda_heu': 5.0,
            'search/resolution_astar': 0.1,
            'search/time_resolution': 0.8,
            'search/margin': 0.2,
            'search/allocate_num': 100000,
            'search/check_num': 5,

            # Trajectory optimization (only set, do not redeclare)
            'optimization/lambda1': 10.0,
            'optimization/lambda2': 5.0,
            'optimization/lambda3': 0.00001,
            'optimization/lambda4': 0.01,
            'optimization/lambda7': 100.0,
            'optimization/dist0': 0.4,
            'optimization/max_vel': 3.0,
            'optimization/max_acc': 2.0,
            'optimization/algorithm1': 15,
            'optimization/algorithm2': 11,
            'optimization/max_iteration_num1': 2,
            'optimization/max_iteration_num2': 300,
            'optimization/max_iteration_num3': 200,
            'optimization/max_iteration_num4': 200,
            'optimization/max_iteration_time1': 0.0001,
            'optimization/max_iteration_time2': 0.005,
            'optimization/max_iteration_time3': 0.003,
            'optimization/max_iteration_time4': 0.003,
            'optimization/order': 3,

            # Bspline
            'bspline/limit_vel': 3.0,
            'bspline/limit_acc': 2.0,
            'bspline/limit_ratio': 1.1,
        }]
    )

    # Trajectory server node
    traj_server_node = Node(
        package='plan_manage',
        executable='traj_server',
        name='traj_server',
        output='screen',
        remappings=[
            ('/position_cmd', 'planning/pos_cmd'),
            ('/odom_world', '/state_ukf/odom'),
        ],
        parameters=[{'traj_server/time_forward': 1.5}]
    )

    # Waypoint generator node
    waypoint_generator_node = Node(
        package='waypoint_generator',
        executable='waypoint_generator',
        name='waypoint_generator',
        output='screen',
        remappings=[
            ('~odom', '/state_ukf/odom'),
            ('~goal', '/move_base_simple/goal'),
            ('~traj_start_trigger', '/traj_start_trigger'),
        ],
        parameters=[{'waypoint_type': 'manual-lonely-waypoint'}]
    )

    # Launch description
    return LaunchDescription([
        fast_planner_node,
        traj_server_node,
        #waypoint_generator_node,
    ])
