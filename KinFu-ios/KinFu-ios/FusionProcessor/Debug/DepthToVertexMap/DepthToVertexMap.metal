//
//  DepthToVertexMap.metal
//  Scanner
//
//  Created by  沈江洋 on 18/01/2018.
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

// depthToVertexMap compute kernel
kernel void
depthToVertexMap(constant float*  currentDepthMap0 [[buffer(0)]],
                 constant float*  currentDepthMap1 [[buffer(1)]],
                 constant float*  currentDepthMap2 [[buffer(2)]],
                 device float*  currentVertexMap0 [[buffer(3)]],
                 device float*  currentVertexMap1 [[buffer(4)]],
                 device float*  currentVertexMap2 [[buffer(5)]],
                 constant float*  preDepthMap0 [[buffer(6)]],
                 constant float*  preDepthMap1 [[buffer(7)]],
                 constant float*  preDepthMap2 [[buffer(8)]],
                 device float*  preVertexMap0 [[buffer(9)]],
                 device float*  preVertexMap1 [[buffer(10)]],
                 device float*  preVertexMap2 [[buffer(11)]],
                 constant Intrinsic_UVD2XYZ &intrinsic_UVD2XYZ0 [[buffer(12)]],
                 constant Intrinsic_UVD2XYZ &intrinsic_UVD2XYZ1 [[buffer(13)]],
                 constant Intrinsic_UVD2XYZ &intrinsic_UVD2XYZ2 [[buffer(14)]],
                 uint2  gid         [[thread_position_in_grid]],
                 uint2  tspg        [[threads_per_grid]])
{
    uint width=tspg.x;
    
    uint invid0=gid.y*width+gid.x;
    uint outvid0=3*invid0;
    if(currentDepthMap0[invid0]<=0.0)
    {
        currentVertexMap0[outvid0]=10000000.0;
        currentVertexMap0[outvid0+1]=10000000.0;
        currentVertexMap0[outvid0+2]=10000000.0;
    }
    else
    {
        float u0=gid.x;
        float v0=gid.y;
        float d0=currentDepthMap0[invid0];
        currentVertexMap0[outvid0]=d0*(u0-intrinsic_UVD2XYZ0.centerU)*intrinsic_UVD2XYZ0.focalInvert;
        currentVertexMap0[outvid0+1]=-d0*(v0-intrinsic_UVD2XYZ0.centerV)*intrinsic_UVD2XYZ0.focalInvert;
        currentVertexMap0[outvid0+2]=-d0;
    }
    if(preDepthMap0[invid0]<=0.0)
    {
        preVertexMap0[outvid0]=10000000.0;
        preVertexMap0[outvid0+1]=10000000.0;
        preVertexMap0[outvid0+2]=10000000.0;
    }
    else
    {
        float u0=gid.x;
        float v0=gid.y;
        float d0=preDepthMap0[invid0];
        preVertexMap0[outvid0]=d0*(u0-intrinsic_UVD2XYZ0.centerU)*intrinsic_UVD2XYZ0.focalInvert;
        preVertexMap0[outvid0+1]=-d0*(v0-intrinsic_UVD2XYZ0.centerV)*intrinsic_UVD2XYZ0.focalInvert;
        preVertexMap0[outvid0+2]=-d0;
    }
    
    
    if(gid.x%2==0&&gid.y%2==0)
    {
        uint invid1=(gid.y*width>>2)+(gid.x>>1);
        uint outvid1=3*invid1;
        if(currentDepthMap1[invid1]<=0.0)
        {
            currentVertexMap1[outvid1]=10000000.0;
            currentVertexMap1[outvid1+1]=10000000.0;
            currentVertexMap1[outvid1+2]=10000000.0;
        }
        else
        {
            float u1=(gid.x>>1);
            float v1=(gid.y>>1);
            float d1=currentDepthMap1[invid1];
            currentVertexMap1[outvid1]=d1*(u1-intrinsic_UVD2XYZ1.centerU)*intrinsic_UVD2XYZ1.focalInvert;
            currentVertexMap1[outvid1+1]=-d1*(v1-intrinsic_UVD2XYZ1.centerV)*intrinsic_UVD2XYZ1.focalInvert;
            currentVertexMap1[outvid1+2]=-d1;
        }
        if(preDepthMap1[invid1]<=0.0)
        {
            preVertexMap1[outvid1]=10000000.0;
            preVertexMap1[outvid1+1]=10000000.0;
            preVertexMap1[outvid1+2]=10000000.0;
        }
        else
        {
            float u1=(gid.x>>1);
            float v1=(gid.y>>1);
            float d1=preDepthMap1[invid1];
            preVertexMap1[outvid1]=d1*(u1-intrinsic_UVD2XYZ1.centerU)*intrinsic_UVD2XYZ1.focalInvert;
            preVertexMap1[outvid1+1]=-d1*(v1-intrinsic_UVD2XYZ1.centerV)*intrinsic_UVD2XYZ1.focalInvert;
            preVertexMap1[outvid1+2]=-d1;
        }
        
        if(gid.x%4==0&&gid.y%4==0)
        {
            uint invid2=(gid.y*width>>4)+(gid.x>>2);
            uint outvid2=3*invid2;
            if(currentDepthMap2[invid2]<=0.0)
            {
                currentVertexMap2[outvid2]=10000000.0;
                currentVertexMap2[outvid2+1]=10000000.0;
                currentVertexMap2[outvid2+2]=10000000.0;
            }
            else
            {
                float u2=(gid.x>>2);
                float v2=(gid.y>>2);
                float d2=currentDepthMap2[invid2];
                currentVertexMap2[outvid2]=d2*(u2-intrinsic_UVD2XYZ2.centerU)*intrinsic_UVD2XYZ2.focalInvert;
                currentVertexMap2[outvid2+1]=-d2*(v2-intrinsic_UVD2XYZ2.centerV)*intrinsic_UVD2XYZ2.focalInvert;
                currentVertexMap2[outvid2+2]=-d2;
            }
            
            if(preDepthMap2[invid2]<=0.0)
            {
                preVertexMap2[outvid2]=10000000.0;
                preVertexMap2[outvid2+1]=10000000.0;
                preVertexMap2[outvid2+2]=10000000.0;
            }
            else
            {
                float u2=(gid.x>>2);
                float v2=(gid.y>>2);
                float d2=preDepthMap2[invid2];
                preVertexMap2[outvid2]=d2*(u2-intrinsic_UVD2XYZ2.centerU)*intrinsic_UVD2XYZ2.focalInvert;
                preVertexMap2[outvid2+1]=-d2*(v2-intrinsic_UVD2XYZ2.centerV)*intrinsic_UVD2XYZ2.focalInvert;
                preVertexMap2[outvid2+2]=-d2;
            }
            
        }
    }
}
