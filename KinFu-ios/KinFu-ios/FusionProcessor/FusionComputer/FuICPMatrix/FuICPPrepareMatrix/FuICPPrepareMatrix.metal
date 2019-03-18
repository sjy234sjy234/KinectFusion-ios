//
//  FuICPPrepareMatrix.metal
//  Scanner
//
//  Created by  沈江洋 on 16/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;



struct ICPThreshold
{
    float maxDistance;
    float maxAngleSin;
};

struct IntrinsicXYZ2UVD
{
    float focal;
    float centerU;
    float centerV;
};

// fuICPPrepareMatrix compute kernel
kernel void
fuICPPrepareMatrix(constant float*  currentVMap [[buffer(0)]],
                 constant float*  currentNMap [[buffer(1)]],
                 constant float*  preVMap [[buffer(2)]],
                 constant float*  preNMap [[buffer(3)]],
                 device float*  icpLMatrix [[buffer(4)]],
                 device float*  icpRMatrix [[buffer(5)]],
                 constant float3x3 &currentF2gRotate [[buffer(6)]],
                 constant float3 &currentF2gTranslate [[buffer(7)]],
                 constant float3x3 &preF2gRotate [[buffer(8)]],
                 constant float3 &preF2gTranslate [[buffer(9)]],
                 constant float3x3 &preG2fRotate [[buffer(10)]],
                 constant float3 &preG2fTranslate [[buffer(11)]],
                 constant ICPThreshold &icpThreshold [[buffer(12)]],
                 constant IntrinsicXYZ2UVD &intrinsic_XYZ2UVD [[buffer(13)]],
                 device atomic_uint &occupiedPixelNumber [[buffer(14)]],
                 uint2  gid         [[thread_position_in_grid]],
                 uint2  tspg        [[threads_per_grid]])
{
    uint width=tspg.x;
    
    uint baseVid=gid.y*width+gid.x;
    uint currentMapVid=3*baseVid;

    float3 currentFrameVertex(currentVMap[currentMapVid],currentVMap[currentMapVid+1],currentVMap[currentMapVid+2]);
    float3 currentFrameNormal(currentNMap[currentMapVid],currentNMap[currentMapVid+1],currentNMap[currentMapVid+2]);
    float3 currentGlobalVertex=currentF2gRotate*currentFrameVertex+currentF2gTranslate;
    float3 currentGlobalNormal=currentF2gRotate*currentFrameNormal;
    
    float3 currInPreFrameVertex=preG2fRotate*currentGlobalVertex+preG2fTranslate;
    float d= -currInPreFrameVertex.z;
    int u= round(currInPreFrameVertex.x*intrinsic_XYZ2UVD.focal/d+intrinsic_XYZ2UVD.centerU);
    int v= round(-currInPreFrameVertex.y*intrinsic_XYZ2UVD.focal/d+intrinsic_XYZ2UVD.centerV);
    if(u<0||u>=tspg.x||v<0||v>=tspg.y)
    {
        return;
    }
    
    uint preMapVid=3*(v*width+u);
    float3 preFrameVertex(preVMap[preMapVid],preVMap[preMapVid+1],preVMap[preMapVid+2]);
    float3 preFrameNormal(preNMap[preMapVid],preNMap[preMapVid+1],preNMap[preMapVid+2]);
    float3 preGlobalVertex=preF2gRotate*preFrameVertex+preF2gTranslate;
    float3 preGlobalNormal=preF2gRotate*preFrameNormal;
    
    float dist=distance(currentGlobalVertex, preGlobalVertex);
    if(dist>icpThreshold.maxDistance)
    {
        return;
    }
    float angleSin=length(cross(currentGlobalNormal, preGlobalNormal));
    if(angleSin>icpThreshold.maxAngleSin)
    {
        return;
    }
    
    float3 coefficient012=cross(preGlobalNormal, currentGlobalVertex);
    float3 coefficient345=preGlobalNormal;
    float constantRightSide=dot(preGlobalNormal, preGlobalVertex-currentGlobalVertex);
    
    uint occupiedPixelIndex = atomic_fetch_add_explicit( &occupiedPixelNumber, 1, memory_order_relaxed );
    
    uint lMatrixVid=6*occupiedPixelIndex;
    uint rMatrixVid=occupiedPixelIndex;
    
    icpLMatrix[lMatrixVid]=coefficient012.x;
    icpLMatrix[lMatrixVid+1]=coefficient012.y;
    icpLMatrix[lMatrixVid+2]=coefficient012.z;
    icpLMatrix[lMatrixVid+3]=coefficient345.x;
    icpLMatrix[lMatrixVid+4]=coefficient345.y;
    icpLMatrix[lMatrixVid+5]=coefficient345.z;
    icpRMatrix[rMatrixVid]=constantRightSide;
}
