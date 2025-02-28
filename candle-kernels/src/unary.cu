#define _USE_MATH_DEFINES
#include<math.h>
#include<stdint.h>
#include "cuda_utils.cuh"

#define UNARY_OP(TYPENAME, FN_NAME, FUNC) \
extern "C" __global__ void FN_NAME( \
    const size_t numel, \
    const size_t num_dims, \
    const size_t *info, \
    const TYPENAME *inp, \
    TYPENAME *out \
) { \
    const size_t *dims = info; \
    const size_t *strides = info + num_dims; \
    if (is_contiguous(num_dims, dims, strides)) { \
        for (unsigned int i = blockIdx.x * blockDim.x + threadIdx.x; i < numel; i += blockDim.x * gridDim.x) { \
            TYPENAME x = inp ? inp[i] : out[i]; \
            out[i] = FUNC; \
        } \
    } \
    else { \
        for (unsigned int i = blockIdx.x * blockDim.x + threadIdx.x; i < numel; i += blockDim.x * gridDim.x) { \
            unsigned strided_i = get_strided_index(i, num_dims, dims, strides); \
            TYPENAME x = inp ? inp[strided_i] : out[i]; \
            out[i] = FUNC; \
        } \
    } \
} \

template<typename T>
__device__ __forceinline__ T gelu_fwd(T x) {
    T x_sq = x * x;
    T x_cube = x_sq * x;
    T alpha = x + static_cast<T>(0.044715) * x_cube;
    return static_cast<T>(0.5) * x * (static_cast<T>(1.0) + tanhg(static_cast<T>(M_2_SQRTPI * M_SQRT1_2) * alpha));
}

template<typename T>
__device__ __forceinline__ T elu_fwd(T x, T alpha) {
  if (x > static_cast<T>(0)) {
    return x;
  }
  return alpha * (expg(x) - static_cast<T>(1));
}

template<typename T>
__device__ __forceinline__ T relu_fwd(T x) {
    T zero = 0.;
    return maxg(x, zero);
}

#define UNARY_OP1(TYPENAME, FN_NAME, FUNC) \
extern "C" __global__ void FN_NAME( \
    const size_t numel, \
    const size_t num_dims, \
    const size_t *info, \
    const TYPENAME param, \
    const TYPENAME *inp, \
    TYPENAME *out \
) { \
    const size_t *dims = info; \
    const size_t *strides = info + num_dims; \
    if (is_contiguous(num_dims, dims, strides)) { \
        for (unsigned int i = blockIdx.x * blockDim.x + threadIdx.x; i < numel; i += blockDim.x * gridDim.x) { \
            TYPENAME x = inp ? inp[i] : out[i]; \
            out[i] = FUNC; \
        } \
    } \
    else { \
        for (unsigned int i = blockIdx.x * blockDim.x + threadIdx.x; i < numel; i += blockDim.x * gridDim.x) { \
            unsigned strided_i = get_strided_index(i, num_dims, dims, strides); \
            TYPENAME x = inp ? inp[strided_i] : out[i]; \
            out[i] = FUNC; \
        } \
    } \
} \


#if __CUDA_ARCH__ >= 800
UNARY_OP(__nv_bfloat16, ucopy_bf16, x)
UNARY_OP(__nv_bfloat16, uneg_bf16, -x)
UNARY_OP(__nv_bfloat16, uexp_bf16, expg(x))
UNARY_OP(__nv_bfloat16, ulog_bf16, logg(x))
UNARY_OP(__nv_bfloat16, usin_bf16, sing(x))
UNARY_OP(__nv_bfloat16, ucos_bf16, cosg(x))
UNARY_OP(__nv_bfloat16, uabs_bf16, absg(x))
UNARY_OP(__nv_bfloat16, usqr_bf16, x*x)
UNARY_OP(__nv_bfloat16, usqrt_bf16, sqrtg(x))
UNARY_OP(__nv_bfloat16, ugelu_bf16, gelu_fwd(x))
UNARY_OP(__nv_bfloat16, urelu_bf16, relu_fwd(x))
UNARY_OP1(__nv_bfloat16, uelu_bf16, elu_fwd(x, param))
#endif

#if __CUDA_ARCH__ >= 530
UNARY_OP(__half, ucopy_f16, x)
UNARY_OP(__half, uneg_f16, -x)
UNARY_OP(__half, uexp_f16, expg(x))
UNARY_OP(__half, ulog_f16, logg(x))
UNARY_OP(__half, usin_f16, sing(x))
UNARY_OP(__half, ucos_f16, cosg(x))
UNARY_OP(__half, uabs_f16, absg(x))
UNARY_OP(__half, usqr_f16, x*x)
UNARY_OP(__half, usqrt_f16, sqrtg(x))
UNARY_OP(__half, ugelu_f16, gelu_fwd(x))
UNARY_OP(__half, urelu_f16, relu_fwd(x))
UNARY_OP1(__half, uelu_f16, elu_fwd(x, param))
#endif

UNARY_OP(uint8_t, ucopy_u8, x)
UNARY_OP(uint32_t, ucopy_u32, x)
UNARY_OP(float, ucopy_f32, x)
UNARY_OP(double, ucopy_f64, x)
UNARY_OP(float, uneg_f32, -x)
UNARY_OP(double, uneg_f64, -x)
UNARY_OP(float, uexp_f32, expg(x))
UNARY_OP(double, uexp_f64, expg(x))
UNARY_OP(float, ulog_f32, logg(x))
UNARY_OP(double, ulog_f64, logg(x))
UNARY_OP(float, usin_f32, sing(x))
UNARY_OP(double, usin_f64, sing(x))
UNARY_OP(float, ucos_f32, cosg(x))
UNARY_OP(double, ucos_f64, cosg(x))
UNARY_OP(float, uabs_f32, absg(x))
UNARY_OP(double, uabs_f64, absg(x))
UNARY_OP(float, usqr_f32, x*x)
UNARY_OP(double, usqr_f64, x*x)
UNARY_OP(float, usqrt_f32, sqrtg(x))
UNARY_OP(double, usqrt_f64, sqrtg(x))
UNARY_OP(float, ugelu_f32, gelu_fwd(x))
UNARY_OP(double, ugelu_f64, gelu_fwd(x))
UNARY_OP(float, urelu_f32, relu_fwd(x))
UNARY_OP(double, urelu_f64, relu_fwd(x))
UNARY_OP1(float, uelu_f32, elu_fwd(x, param))
UNARY_OP1(double, uelu_f64, elu_fwd(x, param))
