//
//  FuPyramidDepthMap.metal
//  Scanner
//
//  Created by  沈江洋 on 04/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// fuPyramidDepthMap compute kernel
kernel void
fuPyramidDepthMap(constant float*  inDepthMap  [[buffer(0)]],
                  device float*  outDepthMap [[buffer(1)]],
                  uint2  gid         [[thread_position_in_grid]],
                  uint2  tspg        [[threads_per_grid]])
{
    
    uint outvid=gid.y*tspg.x+gid.x;
    
    uint inwidth=2*tspg.x;
    uint invid00=(2*gid.y)*inwidth+2*gid.x;
    uint invid10=invid00+1;
    uint invid01=invid00+inwidth;
    uint invid11=invid01+1;
    
    float indepthdata00=inDepthMap[invid00];
    float indepthdata10=inDepthMap[invid10];
    float indepthdata01=inDepthMap[invid01];
    float indepthdata11=inDepthMap[invid11];
    
    //test if it is a valid depth data
    if(indepthdata00<=0.0||indepthdata10<=0.0||indepthdata01<=0.0||indepthdata11<=0.0)
    {
        //for invalid depth block, set depth map to -1.0
        outDepthMap[outvid]=-1.0;
    }
    else
    {
        outDepthMap[outvid]=(indepthdata00+indepthdata10+indepthdata01+indepthdata11)/4.0;
    }
}
