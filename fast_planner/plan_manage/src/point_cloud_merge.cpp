#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <sensor_msgs/point_cloud2_iterator.hpp>

#include <pcl_conversions/pcl_conversions.h>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>

class PointCloudMerger : public rclcpp::Node
{
public:
  PointCloudMerger()
  : Node("pointcloud_merger")
  {
    // Declare parameters
    this->declare_parameter<std::string>("left_topic", "/rgl_lidar/left/world");
    this->declare_parameter<std::string>("right_topic", "/rgl_lidar/right/world");
    this->declare_parameter<std::string>("merged_topic", "/rgl_lidar/merged");

    // Get parameters
    left_topic_ = this->get_parameter("left_topic").as_string();
    right_topic_ = this->get_parameter("right_topic").as_string();
    merged_topic_ = this->get_parameter("merged_topic").as_string();

    RCLCPP_INFO(this->get_logger(), "Left topic: %s", left_topic_.c_str());
    RCLCPP_INFO(this->get_logger(), "Right topic: %s", right_topic_.c_str());
    RCLCPP_INFO(this->get_logger(), "Merged topic: %s", merged_topic_.c_str());

    // Subscribers
    sub_left_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
      left_topic_, 10,
      std::bind(&PointCloudMerger::left_callback, this, std::placeholders::_1));

    sub_right_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
      right_topic_, 10,
      std::bind(&PointCloudMerger::right_callback, this, std::placeholders::_1));

    // Publisher
    pub_merged_ = this->create_publisher<sensor_msgs::msg::PointCloud2>(
      merged_topic_, 10);
  }

private:
  void left_callback(const sensor_msgs::msg::PointCloud2::SharedPtr msg)
  {
    latest_left_ = msg;
    try_publish();
  }

  void right_callback(const sensor_msgs::msg::PointCloud2::SharedPtr msg)
  {
    latest_right_ = msg;
    try_publish();
  }

  void try_publish()
  {
      if (!latest_left_ || !latest_right_) return;

      pcl::PointCloud<pcl::PointXYZ>::Ptr cloud_merged(new pcl::PointCloud<pcl::PointXYZ>);
      pcl::PointCloud<pcl::PointXYZ> cloud_left, cloud_right;

      pcl::fromROSMsg(*latest_left_, cloud_left);
      pcl::fromROSMsg(*latest_right_, cloud_right);

      *cloud_merged = cloud_left;
      *cloud_merged += cloud_right; // very fast in-place merge

      sensor_msgs::msg::PointCloud2 merged_msg;
      pcl::toROSMsg(*cloud_merged, merged_msg);
      merged_msg.header.frame_id = "map";
      merged_msg.header.stamp = this->now();

      pub_merged_->publish(merged_msg);
  }

  // Subscribers & publisher
  rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr sub_left_;
  rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr sub_right_;
  rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr pub_merged_;

  // Latest messages
  sensor_msgs::msg::PointCloud2::SharedPtr latest_left_;
  sensor_msgs::msg::PointCloud2::SharedPtr latest_right_;

  // Parameters
  std::string left_topic_;
  std::string right_topic_;
  std::string merged_topic_;
};

int main(int argc, char **argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<PointCloudMerger>());
  rclcpp::shutdown();
  return 0;
}
