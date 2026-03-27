#include "plan_env/cuda_sdf_map.h"
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cfloat>
#include <algorithm>
#include <iostream>
#include <vector>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <Eigen/Dense>

namespace cuda_sdf_map {

// CUDA error checking macro
#define CUDA_CHECK(call) do { \
    cudaError_t error = call; \
    if (error != cudaSuccess) { \
        std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ << " - " << cudaGetErrorString(error) << std::endl; \
        return false; \
    } \
} while(0)

// Special macro for void functions (like constructor)
#define CUDA_CHECK_VOID(call) do { \
    cudaError_t error = call; \
    if (error != cudaSuccess) { \
        std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ << " - " << cudaGetErrorString(error) << std::endl; \
        return; \
    } \
} while(0)

// CUDA kernel for point cloud processing - functionally equivalent to OpenMP version
__global__ void processPointCloudKernel(
    const float* points_x,
    const float* points_y, 
    const float* points_z,
    const size_t num_points,
    const float camera_x,
    const float camera_y,
    const float camera_z,
    const float local_range_x,
    const float local_range_y,
    const float local_range_z,
    const float resolution,
    const int inf_step,
    const int inf_step_z,
    const int map_size_x,
    const int map_size_y,
    const int map_size_z,
    const float origin_x,
    const float origin_y,
    const float origin_z,
    uint8_t* occupancy_buffer,
    float* bounds_buffer
) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Initialize thread-local bounds to camera position (like CPU version)
    float thread_min_x = camera_x;
    float thread_min_y = camera_y;
    float thread_min_z = camera_z;
    float thread_max_x = camera_x;
    float thread_max_y = camera_y;
    float thread_max_z = camera_z;
    
    bool thread_has_valid_points = false;
    
    // Process points assigned to this thread
    if (idx < num_points) {
        float pt_x = points_x[idx];
        float pt_y = points_y[idx];
        float pt_z = points_z[idx];
        
        float dev_x = pt_x - camera_x;
        float dev_y = pt_y - camera_y;
        float dev_z = pt_z - camera_z;
        
        // Check if point is within local update range (same as CPU version)
        if (fabsf(dev_x) < local_range_x && 
            fabsf(dev_y) < local_range_y && 
            fabsf(dev_z) < local_range_z) {
            
            // Process inflation around this point (same nested loops as CPU)
            for (int x = -inf_step; x <= inf_step; ++x) {
                for (int y = -inf_step; y <= inf_step; ++y) {
                    for (int z = -inf_step_z; z <= inf_step_z; ++z) {
                        float inf_x = pt_x + x * resolution;
                        float inf_y = pt_y + y * resolution;
                        float inf_z = pt_z + z * resolution;
                        
                        // Convert to grid indices
                        int grid_x = __float2int_rd((inf_x - origin_x) / resolution);
                        int grid_y = __float2int_rd((inf_y - origin_y) / resolution);
                        int grid_z = __float2int_rd((inf_z - origin_z) / resolution);
                        
                        // Check bounds first (same as CPU: isInMap check)
                        if (grid_x >= 0 && grid_x < map_size_x &&
                            grid_y >= 0 && grid_y < map_size_y &&
                            grid_z >= 0 && grid_z < map_size_z) {
                            
                            // Only update bounds for points that are actually in the map
                            // This matches the CPU version behavior
                            if (inf_x > thread_max_x) thread_max_x = inf_x;
                            if (inf_y > thread_max_y) thread_max_y = inf_y;
                            if (inf_z > thread_max_z) thread_max_z = inf_z;
                            if (inf_x < thread_min_x) thread_min_x = inf_x;
                            if (inf_y < thread_min_y) thread_min_y = inf_y;
                            if (inf_z < thread_min_z) thread_min_z = inf_z;
                            
                            thread_has_valid_points = true;
                            
                            // Set occupancy using same memory layout as CPU (toAddress equivalent)
                            // CPU uses: id(0) * map_voxel_num_(1) * map_voxel_num_(2) + id(1) * map_voxel_num_(2) + id(2)
                            int buffer_idx = grid_x * map_size_y * map_size_z + grid_y * map_size_z + grid_z;
                            occupancy_buffer[buffer_idx] = 1;
                        }
                    }
                }
            }
        }
    }
    
    // Shared memory for block-level reductions
    __shared__ float s_min_x[256], s_min_y[256], s_min_z[256];
    __shared__ float s_max_x[256], s_max_y[256], s_max_z[256];
    __shared__ bool s_valid[256];
    
    // Store thread results in shared memory
    s_min_x[threadIdx.x] = thread_min_x;
    s_min_y[threadIdx.x] = thread_min_y;
    s_min_z[threadIdx.x] = thread_min_z;
    s_max_x[threadIdx.x] = thread_max_x;
    s_max_y[threadIdx.x] = thread_max_y;
    s_max_z[threadIdx.x] = thread_max_z;
    s_valid[threadIdx.x] = thread_has_valid_points;
    
    __syncthreads();
    
    // Block-level reduction
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (threadIdx.x < stride) {
            // Only update if the other thread had valid points
            if (s_valid[threadIdx.x + stride]) {
                if (!s_valid[threadIdx.x]) {
                    // Current thread has no valid points, take from other thread
                    s_min_x[threadIdx.x] = s_min_x[threadIdx.x + stride];
                    s_min_y[threadIdx.x] = s_min_y[threadIdx.x + stride];
                    s_min_z[threadIdx.x] = s_min_z[threadIdx.x + stride];
                    s_max_x[threadIdx.x] = s_max_x[threadIdx.x + stride];
                    s_max_y[threadIdx.x] = s_max_y[threadIdx.x + stride];
                    s_max_z[threadIdx.x] = s_max_z[threadIdx.x + stride];
                    s_valid[threadIdx.x] = true;
                } else {
                    // Both threads have valid points, do proper min/max
                    s_min_x[threadIdx.x] = fminf(s_min_x[threadIdx.x], s_min_x[threadIdx.x + stride]);
                    s_min_y[threadIdx.x] = fminf(s_min_y[threadIdx.x], s_min_y[threadIdx.x + stride]);
                    s_min_z[threadIdx.x] = fminf(s_min_z[threadIdx.x], s_min_z[threadIdx.x + stride]);
                    s_max_x[threadIdx.x] = fmaxf(s_max_x[threadIdx.x], s_max_x[threadIdx.x + stride]);
                    s_max_y[threadIdx.x] = fmaxf(s_max_y[threadIdx.x], s_max_y[threadIdx.x + stride]);
                    s_max_z[threadIdx.x] = fmaxf(s_max_z[threadIdx.x], s_max_z[threadIdx.x + stride]);
                }
            }
        }
        __syncthreads();
    }
    
    // Write block results to global memory
    if (threadIdx.x == 0) {
        int block_idx = blockIdx.x;
        bounds_buffer[block_idx * 7 + 0] = s_min_x[0];
        bounds_buffer[block_idx * 7 + 1] = s_min_y[0];
        bounds_buffer[block_idx * 7 + 2] = s_min_z[0];
        bounds_buffer[block_idx * 7 + 3] = s_max_x[0];
        bounds_buffer[block_idx * 7 + 4] = s_max_y[0];
        bounds_buffer[block_idx * 7 + 5] = s_max_z[0];
        bounds_buffer[block_idx * 7 + 6] = s_valid[0] ? 1.0f : 0.0f; // validity flag
    }
}

// CUDA implementation details (PIMPL)
struct CudaProcessorImpl {
    float* d_points_x_;
    float* d_points_y_;
    float* d_points_z_;
    uint8_t* d_occupancy_buffer_;
    float* d_bounds_buffer_;
    
    size_t max_points_;
    size_t max_buffer_size_;
    cudaStream_t stream_;
    bool initialized_;
    
    CudaProcessorImpl(size_t max_points, size_t max_buffer_size) 
        : max_points_(max_points), max_buffer_size_(max_buffer_size), initialized_(false) {
        
        // Allocate device memory
        cudaError_t error = cudaSuccess;
        error = cudaMalloc(&d_points_x_, max_points_ * sizeof(float));
        if (error != cudaSuccess) return;
        
        error = cudaMalloc(&d_points_y_, max_points_ * sizeof(float));
        if (error != cudaSuccess) return;
        
        error = cudaMalloc(&d_points_z_, max_points_ * sizeof(float));
        if (error != cudaSuccess) return;
        
        error = cudaMalloc(&d_occupancy_buffer_, max_buffer_size_ * sizeof(uint8_t));
        if (error != cudaSuccess) return;
        
        error = cudaMalloc(&d_bounds_buffer_, 1024 * 7 * sizeof(float)); // 7 elements per block (6 bounds + 1 valid flag)
        if (error != cudaSuccess) return;
        
        error = cudaStreamCreate(&stream_);
        if (error != cudaSuccess) return;
        
        initialized_ = true;
    }
    
    ~CudaProcessorImpl() {
        if (initialized_) {
            cudaFree(d_points_x_);
            cudaFree(d_points_y_);
            cudaFree(d_points_z_);
            cudaFree(d_occupancy_buffer_);
            cudaFree(d_bounds_buffer_);
            cudaStreamDestroy(stream_);
        }
    }
};

// Public interface implementation
bool isCudaAvailable() {
    int deviceCount = 0;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);
    return (error == cudaSuccess && deviceCount > 0);
}

cuda_sdf_map::CudaProcessor::CudaProcessor(size_t max_points, size_t max_buffer_size) {
    impl_ = new CudaProcessorImpl(max_points, max_buffer_size);
    initialized_ = static_cast<CudaProcessorImpl*>(impl_)->initialized_;
}

cuda_sdf_map::CudaProcessor::~CudaProcessor() {
    delete static_cast<CudaProcessorImpl*>(impl_);
}

bool CudaProcessor::processPointCloud(
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
) {
    if (!initialized_) return false;
    
    CudaProcessorImpl* pImpl = static_cast<CudaProcessorImpl*>(impl_);
    size_t num_points = cloud.points.size();
    if (num_points == 0) return true;
    
    // Prepare host data
    std::vector<float> h_points_x(num_points), h_points_y(num_points), h_points_z(num_points);
    for (size_t i = 0; i < num_points; ++i) {
        h_points_x[i] = cloud.points[i].x;
        h_points_y[i] = cloud.points[i].y;
        h_points_z[i] = cloud.points[i].z;
    }
    
    // Copy point data to device
    CUDA_CHECK(cudaMemcpyAsync(pImpl->d_points_x_, h_points_x.data(), num_points * sizeof(float), 
                   cudaMemcpyHostToDevice, pImpl->stream_));
    CUDA_CHECK(cudaMemcpyAsync(pImpl->d_points_y_, h_points_y.data(), num_points * sizeof(float), 
                   cudaMemcpyHostToDevice, pImpl->stream_));
    CUDA_CHECK(cudaMemcpyAsync(pImpl->d_points_z_, h_points_z.data(), num_points * sizeof(float), 
                   cudaMemcpyHostToDevice, pImpl->stream_));
    
    // Reset occupancy buffer
    CUDA_CHECK(cudaMemsetAsync(pImpl->d_occupancy_buffer_, 0, occupancy_buffer.size() * sizeof(uint8_t), pImpl->stream_));
    
    // Calculate kernel parameters
    const int threads_per_block = 256;
    int blocks_per_grid = (num_points + threads_per_block - 1) / threads_per_block;
    blocks_per_grid = std::min(blocks_per_grid, 1024);
    
    int inf_step = ceil(obstacles_inflation / resolution);
    
    // Launch kernel
    processPointCloudKernel<<<blocks_per_grid, threads_per_block, 0, pImpl->stream_>>>(
        pImpl->d_points_x_, pImpl->d_points_y_, pImpl->d_points_z_,
        num_points,
        camera_pos.x(), camera_pos.y(), camera_pos.z(),
        local_update_range.x(), local_update_range.y(), local_update_range.z(),
        resolution, inf_step, 1, // inf_step_z = 1 like CPU version
        map_size.x(), map_size.y(), map_size.z(),
        map_origin.x(), map_origin.y(), map_origin.z(),
        pImpl->d_occupancy_buffer_,
        pImpl->d_bounds_buffer_
    );
    
    CUDA_CHECK(cudaGetLastError()); // Check for kernel launch errors
    
    // Copy results back
    CUDA_CHECK(cudaMemcpyAsync(occupancy_buffer.data(), pImpl->d_occupancy_buffer_, 
                   occupancy_buffer.size() * sizeof(uint8_t), cudaMemcpyDeviceToHost, pImpl->stream_));
    
    // Get bounds (now 7 elements per block: 6 bounds + 1 validity flag)
    std::vector<float> h_bounds_buffer(blocks_per_grid * 7);
    CUDA_CHECK(cudaMemcpyAsync(h_bounds_buffer.data(), pImpl->d_bounds_buffer_, 
                   blocks_per_grid * 7 * sizeof(float), cudaMemcpyDeviceToHost, pImpl->stream_));
    
    CUDA_CHECK(cudaStreamSynchronize(pImpl->stream_));
    
    // Initialize bounds to camera position (same as CPU version)
    min_x = camera_pos.x(); min_y = camera_pos.y(); min_z = camera_pos.z();
    max_x = camera_pos.x(); max_y = camera_pos.y(); max_z = camera_pos.z();
    
    // Reduce bounds on CPU - only consider blocks that had valid points
    for (int i = 0; i < blocks_per_grid; ++i) {
        if (h_bounds_buffer[i * 7 + 6] > 0.5f) { // Check validity flag
            min_x = std::min(min_x, (double)h_bounds_buffer[i * 7 + 0]);
            min_y = std::min(min_y, (double)h_bounds_buffer[i * 7 + 1]);
            min_z = std::min(min_z, (double)h_bounds_buffer[i * 7 + 2]);
            max_x = std::max(max_x, (double)h_bounds_buffer[i * 7 + 3]);
            max_y = std::max(max_y, (double)h_bounds_buffer[i * 7 + 4]);
            max_z = std::max(max_z, (double)h_bounds_buffer[i * 7 + 5]);
        }
    }
}

} // namespace cuda_sdf_map