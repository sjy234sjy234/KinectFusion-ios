//
//  VertexToNormalMap.metal
//  Scanner
//
//  Created by  沈江洋 on 05/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// vertexToNormal compute kernel
kernel void
vertexToNormal(constant float*  inVertexMap  [[buffer(0)]],
                 device float*  outNormalMap [[buffer(1)]],
                 uint2  gid         [[thread_position_in_grid]],
                 uint2  tspg        [[threads_per_grid]])
{
    
    uint vidcenter=3*(gid.y*tspg.x+gid.x);
    uint vidright=vidcenter+3;
    uint vidup=vidcenter-3*tspg.x;
    
    if(gid.x==0||(gid.x==tspg.x-1)||gid.y==0||(gid.y==tspg.y-1))
    {
        //for boundry, set normal to unreasonable value
        outNormalMap[vidcenter]=10000000.0;
        outNormalMap[vidcenter+1]=10000000.0;
        outNormalMap[vidcenter+2]=10000000.0;
        return;
    }
    
    if(inVertexMap[vidcenter]>1000000.0||inVertexMap[vidright]>1000000.0||inVertexMap[vidup]>1000000.0)
    {
        //for invalid point, set normal to unreasonable value
        outNormalMap[vidcenter]=10000000.0;
        outNormalMap[vidcenter+1]=10000000.0;
        outNormalMap[vidcenter+2]=10000000.0;
        return;
    }
    
    float3 vertexcenter(inVertexMap[vidcenter],inVertexMap[vidcenter+1],inVertexMap[vidcenter+2]);
    float3 vertexright(inVertexMap[vidright],inVertexMap[vidright+1],inVertexMap[vidright+2]);
    float3 vertexup(inVertexMap[vidup],inVertexMap[vidup+1],inVertexMap[vidup+2]);
    float3 normal=normalize(cross(vertexright-vertexcenter, vertexup-vertexcenter));
    
    outNormalMap[vidcenter]=normal.x;
    outNormalMap[vidcenter+1]=normal.y;
    outNormalMap[vidcenter+2]=normal.z;
}
