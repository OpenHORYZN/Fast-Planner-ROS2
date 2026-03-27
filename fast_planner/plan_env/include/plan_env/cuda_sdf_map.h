#ifndef CUDA_SDF_MAP_H
#define CUDA_SDF_MAP_H

#include <Eigen/Dense>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <vector>

namespace cuda_sdf_map {

// Check if CUDA is available at runtime
bool isCudaAvailable();

// CUDA-accelerated point cloud processing
class CudaProcessor {
public:
    CudaProcessor(size_t max_points = 1000000, size_t max_buffer_size = 10000000);
    ~CudaProcessor();
    
    // Main processing function that matches your original loop
    bool processPointCloud(
        const pcl::PointCloud<pcl::PointXYZ>& cloud,
        const Eigen::Vector3d& camera_pos,
        const Eigen::Vector3d& local_update_range,
        double resolution,
        double obstacles_inflation,
        const Eigen::Vector3i& map_size,
        const Eigen::Vector3d& map_origin,
        std::vector<uint8_t>& occupancy_buffer,
        double& min_x, double& min_y, double& min_z,
        double& max_x, double& max_y, double& max_z
    );
    
    // Check if processor is ready
    bool isInitialized() const { return initialized_; }
    
private:
    bool initialized_;
    void* impl_; // PIMPL idiom to hide CUDA details from header
};

} // namespace cuda_sdf_map

#endif // CUDA_SDF_MAP_H