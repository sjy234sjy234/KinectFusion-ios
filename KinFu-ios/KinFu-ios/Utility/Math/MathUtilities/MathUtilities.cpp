#import "MathUtilities.hpp"

float4x4 matrix_float4x4_translation(const float3 &t)
{
    vector_float4 X = { 1, 0, 0, 0 };
    vector_float4 Y = { 0, 1, 0, 0 };
    vector_float4 Z = { 0, 0, 1, 0 };
    vector_float4 W = { t.x, t.y, t.z, 1 };
    
    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 matrix_float4x4_translation(const float &x, const float &y, const float&z)
{
    vector_float4 X = { 1, 0, 0, 0 };
    vector_float4 Y = { 0, 1, 0, 0 };
    vector_float4 Z = { 0, 0, 1, 0 };
    vector_float4 W = { x, y, z, 1 };
    
    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 matrix_float4x4_uniform_scale(const float &scale)
{
    vector_float4 X = { scale, 0, 0, 0 };
    vector_float4 Y = { 0, scale, 0, 0 };
    vector_float4 Z = { 0, 0, scale, 0 };
    vector_float4 W = { 0, 0, 0, 1 };
    
    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 matrix_float4x4_scale(const float &scalex, const float &scaley, const float &scalez)
{
    vector_float4 X = { scalex, 0, 0, 0 };
    vector_float4 Y = { 0, scaley, 0, 0 };
    vector_float4 Z = { 0, 0, scalez, 0 };
    vector_float4 W = { 0, 0, 0, 1 };
    
    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 matrix_float4x4_rotation(const float3 &axis, const float &angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    float4 X;
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z * s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    float4 Y;
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    float4 Z;
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    float4 W;
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 matrix_float4x4_rotation(const float &x, const float &y, const float &z, const float &w)
{
    double xx=x*x;
    double xy=x*y;
    double xz=x*z;
    double xw=x*w;
    
    double yy=y*y;
    double yz=y*z;
    double yw=y*w;
    
    double zz=z*z;
    double zw=z*w;
    
    simd::float4 P;
    simd::float4 Q;
    simd::float4 R;
    simd::float4 S;
    
    P.x = 1 - 2 * ( yy + zz );
    P.y = 2 * ( xy + zw );
    P.z = 2 * ( xz - yw );
    P.w = 0.0f;
    
    Q.x = 2 * ( xy - zw );
    Q.y = 1 - 2 * ( xx + zz );
    Q.z = 2 * ( yz + xw );
    Q.w = 0.0f;
    
    R.x = 2 * ( xz + yw );
    R.y = 2 * ( yz - xw );
    R.z = 1 - 2 * ( xx + yy );
    R.w = 0.0f;
    
    S.x = 0;
    S.y = 0;
    S.z = 0;
    S.w = 1.0f;
    
    return simd::float4x4(P, Q, R, S);
}

float3x3 matrix_float3x3_rotation(const float3 &axis, const float &angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    float3 X;
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z * s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    
    float3 Y;
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    
    
    float3 Z;
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    
    float3x3 mat = { X, Y, Z };
    return mat;
}

float3x3 matrix_float3x3_rotation(const float &rotatex, const float &rotatey, const float &rotatez)
{
    float3 xAxis={1.0, 0.0, 0.0};
    float3 yAxis={0.0, 1.0, 0.0};
    float3 zAxis={0.0, 0.0, 1.0};
    
    float3x3 xRotateMat=matrix_float3x3_rotation(xAxis, rotatex);
    float3x3 yRotateMat=matrix_float3x3_rotation(yAxis, rotatey);
    float3x3 zRotateMat=matrix_float3x3_rotation(zAxis, rotatez);
    
    return zRotateMat*yRotateMat*xRotateMat;
}

float4x4 matrix_float4x4_perspective(const float &aspect, const float & fovy, const float & near, const float & far)
{
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far + near) / zRange;
    float wzScale = -2 * far * near / zRange;
    
    float4 P = { xScale, 0, 0, 0 };
    float4 Q = { 0, yScale, 0, 0 };
    float4 R = { 0, 0, zScale, -1 };
    float4 S = { 0, 0, wzScale, 0 };
    
    float4x4 mat = { P, Q, R, S };
    return mat;
}

void matrix_transform_extract(const float4x4 &transform, float3x3 &rotate, float3 &translate)
{
    rotate.columns[0].x=transform.columns[0].x;
    rotate.columns[0].y=transform.columns[0].y;
    rotate.columns[0].z=transform.columns[0].z;
    
    rotate.columns[1].x=transform.columns[1].x;
    rotate.columns[1].y=transform.columns[1].y;
    rotate.columns[1].z=transform.columns[1].z;
    
    rotate.columns[2].x=transform.columns[2].x;
    rotate.columns[2].y=transform.columns[2].y;
    rotate.columns[2].z=transform.columns[2].z;
    
    translate.x=transform.columns[3].x;
    translate.y=transform.columns[3].y;
    translate.z=transform.columns[3].z;
}

void matrix_transform_compose(float4x4 &transform, const float3x3 &rotate, const float3 &translate)
{
    transform.columns[0].x=rotate.columns[0].x;
    transform.columns[0].y=rotate.columns[0].y;
    transform.columns[0].z=rotate.columns[0].z;
    transform.columns[0].w=0.0;
    
    transform.columns[1].x=rotate.columns[1].x;
    transform.columns[1].y=rotate.columns[1].y;
    transform.columns[1].z=rotate.columns[1].z;
    transform.columns[1].w=0.0;
    
    transform.columns[2].x=rotate.columns[2].x;
    transform.columns[2].y=rotate.columns[2].y;
    transform.columns[2].z=rotate.columns[2].z;
    transform.columns[2].w=0.0;
    
    transform.columns[3].x=translate.x;
    transform.columns[3].y=translate.y;
    transform.columns[3].z=translate.z;
    transform.columns[3].w=1.0;
}

bool matrix_float6x6_solve(const float* icpLeftReduce, const float* icpRightReduce, float* result)
{
    
    
    Eigen::Matrix<float,6,1> resultDeputy;
    
    Eigen::Matrix<float, 6, 6, Eigen::RowMajor> A;
    
    for(int i=0;i<6;++i)
    {
        for(int j=0;j<6;++j)
        {
            A(i,j)=icpLeftReduce[i*6+j];
        }
    }
    float det=A.determinant();
    if(fabs(det)<std::numeric_limits<float>::epsilon()||!(det==det))
    {
        return false;
    }
    
    Eigen::Matrix<float, 6, 1> b;
    
    for(int i=0;i<6;++i)
    {
        b(i)=icpRightReduce[i];
    }
    
    resultDeputy=A.llt().solve(b).cast<float>();
    
    for(int i=0;i<6;++i)
    {
        result[i]=resultDeputy[i];
    }
    
    return true;
}

void matrix_eulerian_angle(const float4x4 &rotateM, float3 &rotateV)
{
    float T[9],E[3];
    for(int i=0;i<3;++i)
    {
        T[i*3+0]=rotateM.columns[i].x;
        T[i*3+1]=rotateM.columns[i].y;
        T[i*3+2]=rotateM.columns[i].z;
    }
    E[0] = atan2(T[1],T[0]);
    E[1] = atan2(-1*T[2],(T[0]*cos(E[0])+T[1]*sin(E[0])));
    E[2] = atan2((T[6]*sin(E[0])-T[7]*cos(E[0])),(-1*T[3]*sin(E[0])+T[4]*cos(E[0])));
    rotateV.x=-E[2];
    rotateV.y=-E[1];
    rotateV.z=-E[0];
}

void matrix_quaternion_angle(const float4x4 &rotateMatrix, float4 &quaternion)
{
    Eigen::Matrix3f rm;
    for(int i=0;i<3;++i)
    {
        rm(0,i)=rotateMatrix.columns[i].x;
        rm(1,i)=rotateMatrix.columns[i].y;
        rm(2,i)=rotateMatrix.columns[i].z;
    }
    Eigen::Quaternionf q(rm);
    quaternion.x=q.x();
    quaternion.y=q.y();
    quaternion.z=q.z();
    quaternion.w=q.w();
}

