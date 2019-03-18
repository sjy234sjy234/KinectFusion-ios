//
//  DepthToVertex.metal
//  Scanner
//
//  Created by  沈江洋 on 04/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Intrinsic_UVD2XYZ
{
    float focalInvert;
    float centerU;
    float centerV;
};

// depthToVertex compute kernel
kernel void
depthToVertex(constant float*  inDepthMap  [[buffer(0)]],
                device float*  outVertexMap [[buffer(1)]],
                constant Intrinsic_UVD2XYZ &intrinsic_UVD2XYZ [[buffer(2)]],
                uint2  gid         [[thread_position_in_grid]],
                uint2  tspg        [[threads_per_grid]])
{
    
    uint invid=gid.y*tspg.x+gid.x;
    uint outvid=3*invid;
    
    float u=gid.x;
    float v=gid.y;
    float d=inDepthMap[invid];
    
    float focalInvert=intrinsic_UVD2XYZ.focalInvert;
    float centerU=intrinsic_UVD2XYZ.centerU;
    float centerV=intrinsic_UVD2XYZ.centerV;
    
    //test if it is a valid depth data
    if(d<=0.0)
    {
        //for invalid depth data, set vertex to unreasonable value
        outVertexMap[outvid]=10000000.0;
        outVertexMap[outvid+1]=10000000.0;
        outVertexMap[outvid+2]=10000000.0;
    }
    else
    {
        outVertexMap[outvid]=d*(u-centerU)*focalInvert;
        outVertexMap[outvid+1]=-d*(v-centerV)*focalInvert;
        outVertexMap[outvid+2]=-d;
    }
}
