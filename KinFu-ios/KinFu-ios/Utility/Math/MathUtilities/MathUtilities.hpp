#include <simd/simd.h>
#include "Eigen.hpp"

using namespace simd;

typedef struct
{
    float4 position;
    float2 texCoords;
} TextureVertex;

/// Builds a translation matrix that translates by the supplied vector
float4x4 matrix_float4x4_translation(const float3 &t);

float4x4 matrix_float4x4_translation(const float &x, const float &y, const float&z);

/// Builds a scale matrix that uniformly scales all axes by the supplied factor
float4x4 matrix_float4x4_uniform_scale(const float &scale);

float4x4 matrix_float4x4_scale(const float &scalex, const float &scaley, const float &scalez);

/// Builds a rotation matrix that rotates about the supplied axis by an
/// angle (given in radians). The axis should be normalized.
float4x4 matrix_float4x4_rotation(const float3 &axis, const float &angle);

float4x4 matrix_float4x4_rotation(const float &x, const float &y, const float &z, const float &w);

float3x3 matrix_float3x3_rotation(const float3 &axis, const float &angle);

float3x3 matrix_float3x3_rotation(const float &rotatex, const float &rotatey, const float &rotatez);

/// Builds a symmetric perspective projection matrix with the supplied aspect ratio,
/// vertical field of view (in radians), and near and far distances
float4x4 matrix_float4x4_perspective(const float &aspect, const float & fovy, const float & near, const float & far);

void matrix_transform_extract(const float4x4 &transform, float3x3 &rotate, float3 &translate);

void matrix_transform_compose(float4x4 &transform, const float3x3 &rotate, const float3 &translate);

bool matrix_float6x6_solve(const float* icpLeftReduce, const float* icpRightReduce, float* result);

void matrix_eulerian_angle(const float4x4 &rotateM, float3 &rotateV);

void matrix_quaternion_angle(const float4x4 &rotateMatrix, float4 &quaternion);

