/**
* This file is part of Fast-Planner.
*
* Copyright 2019 Boyu Zhou, Aerial Robotics Group, Hong Kong University of Science and Technology, <uav.ust.hk>
* Developed by Boyu Zhou <bzhouai at connect dot ust dot hk>, <uv dot boyuzhou at gmail dot com>
* for more information see <https://github.com/HKUST-Aerial-Robotics/Fast-Planner>.
* If you use this code, please cite the respective publications as
* listed on the above website.
*
* Fast-Planner is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Fast-Planner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with Fast-Planner. If not, see <http://www.gnu.org/licenses/>.
*/



#include <rclcpp/logger.hpp>
#include <rclcpp/logging.hpp>
#include <rclcpp/rclcpp.hpp>
#include <visualization_msgs/msg/marker.hpp>

#include <plan_manage/kino_replan_fsm.h>
#include <plan_manage/topo_replan_fsm.h>

#include <plan_manage/backward.hpp>
namespace backward {
backward::SignalHandling sh;
}

using namespace fast_planner;

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);

    // create a node
    auto node = std::make_shared<rclcpp::Node>("planner_node");

    // get parameter (declare first in ROS2)
    int planner;
    node->declare_parameter("planner_node/planner", -1);
    planner = node->get_parameter("planner_node/planner").as_int();

    TopoReplanFSM topo_replan;
    KinoReplanFSM kino_replan;

    if (planner == 1) {
        kino_replan.init(node);
        RCLCPP_INFO(rclcpp::get_logger("START"), "Using kino replanning.");
    } else if (planner == 2) {
        topo_replan.init(node);
        RCLCPP_INFO(rclcpp::get_logger("START"), "Using topo replanning.");
    }

    // sleep for 1 second
    rclcpp::sleep_for(std::chrono::seconds(1));

    // spin the node
    rclcpp::spin(node);

    rclcpp::shutdown();
    return 0;
}
