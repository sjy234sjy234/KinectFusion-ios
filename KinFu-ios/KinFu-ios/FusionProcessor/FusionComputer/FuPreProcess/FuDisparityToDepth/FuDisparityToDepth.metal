//
//  FuDisparityToDepth.metal
//  Scanner
//
//  Created by 沈江洋 on 03/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// fuDisparityToDepth compute kernel
kernel void
fuDisparityToDepth(constant half*  inDisparityBuffer  [[buffer(0)]],
                    device float* outDepthMapBuffer  [[buffer(1)]],
                    uint2  gid         [[thread_position_in_grid]],
                    uint2  tspg        [[threads_per_grid]])
{
    uint vid = gid.y*tspg.x+gid.x;
    
    half inDisparityValue  = inDisparityBuffer[vid];
    //test if it is a valid disparity data
    if(inDisparityValue<=0.0)
    {
        //for invalid disparity data, set depth map to -1.0
        outDepthMapBuffer[vid]=-1.0;
    }
    else
    {
        outDepthMapBuffer[vid]=1000.0/inDisparityValue;
    }
}
