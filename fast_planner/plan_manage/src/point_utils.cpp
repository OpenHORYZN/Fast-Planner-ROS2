#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <tf2/LinearMath/Transform.h>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2_sensor_msgs/tf2_sensor_msgs.h>

#include <geometry_msgs/msg/transform_stamped.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>

class PointCloudUtils : public rclcpp::Node {
private:
    rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
    rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr cloud_sub_;
    rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr cloud_pub_;

    nav_msgs::msg::Odometry::SharedPtr latest_odom_;

public:
    PointCloudUtils(const std::string &node_name) : Node(node_name) {
        // Topics
        std::string cloud_topic = this->declare_parameter("cloud_topic", "/sdf_map/cloud");
        std::string odom_topic  = this->declare_parameter("odom_topic", "/odom_world");
        std::string pub_topic   = this->declare_parameter("pub_topic", "/cloud_in_base");

        // QoS
        rclcpp::QoS odom_qos(10);
        odom_qos.best_effort().durability_volatile();
        rclcpp::QoS cloud_qos(10);
        cloud_qos.reliable().durability_volatile();

        // Subscriptions
        odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
            odom_topic, odom_qos,
            [this](nav_msgs::msg::Odometry::SharedPtr msg) {
                latest_odom_ = msg;  // store latest odometry
            }
        );

        cloud_sub_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
            cloud_topic, cloud_qos,
            std::bind(&PointCloudUtils::cloudCallback, this, std::placeholders::_1)
        );

        // Publisher
        cloud_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>(pub_topic, cloud_qos);

        RCLCPP_INFO_STREAM(this->get_logger(), "Subscribed to cloud: " << cloud_topic);
        RCLCPP_INFO_STREAM(this->get_logger(), "Subscribed to odom: " << odom_topic);
        RCLCPP_INFO_STREAM(this->get_logger(), "Publishing transformed cloud on: " << pub_topic);
    }

private:
    void cloudCallback(const sensor_msgs::msg::PointCloud2::SharedPtr pt) {
        if (!latest_odom_) {
            RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
                                 "No odometry received yet, skipping cloud");
            return;
        }
        /*
        // Build transform from odom -> base_link
        tf2::Transform tf_map_to_base;
        const auto &odom = latest_odom_->pose.pose;
        tf2::Quaternion q(odom.orientation.x, odom.orientation.y, odom.orientation.z, odom.orientation.w);
        tf_map_to_base.setRotation(q);
        tf_map_to_base.setOrigin(tf2::Vector3(odom.position.x, odom.position.y, odom.position.z));

        tf2::Transform tf_base_to_map = tf_map_to_base.inverse();

        geometry_msgs::msg::TransformStamped tf_msg;
        tf_msg.header = pt->header;
        tf_msg.child_frame_id = "base_link";
        tf_msg.transform.translation.x = tf_base_to_map.getOrigin().x();
        tf_msg.transform.translation.y = tf_base_to_map.getOrigin().y();
        tf_msg.transform.translation.z = tf_base_to_map.getOrigin().z();
        tf2::Quaternion q_base_to_map = tf_base_to_map.getRotation();
        tf_msg.transform.rotation.x = q_base_to_map.x();
        tf_msg.transform.rotation.y = q_base_to_map.y();
        tf_msg.transform.rotation.z = q_base_to_map.z();
        tf_msg.transform.rotation.w = q_base_to_map.w();

        // Transform the point cloud
        sensor_msgs::msg::PointCloud2 cloud_out;
        tf2::doTransform(*pt, cloud_out, tf_msg);
        */
        

        pt->header.frame_id = "map";
        cloud_pub_->publish(*pt);
    }
};

int main(int argc, char **argv) {
    rclcpp::init(argc, argv);
    auto node = std::make_shared<PointCloudUtils>("point_utils_node");
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
