//
//  DisparityToDepthMap.metal
//  Scanner
//
//  Created by  沈江洋 on /Users/sjy234/Documents/work/fushion development/develop/Scanner_Metal/Scanner/MetalFushion/MetalDisparityToDepthMap.metal03/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// disparityToDepth compute kernel
kernel void
disparityToDepth(constant half*  inDisparityBuffer  [[buffer(0)]],
                    device float* outDepthMapBuffer  [[buffer(1)]],
                    uint2  gid         [[thread_position_in_grid]],
                    uint2  tspg        [[threads_per_grid]])
{
    //in disparity size: 640*480
    uint invid=gid.x*tspg.y+gid.y;
    //out depth size:    480*640
    uint outvid=gid.y*tspg.x+gid.x;
    
    half inDisparityValue  = inDisparityBuffer[invid];
    //test if it is a valid disparity data
    if(inDisparityValue<=0.0)
    {
        //for invalid disparity data, set depth map to -1.0
        outDepthMapBuffer[outvid]=-1.0;
    }
    else
    {
        outDepthMapBuffer[outvid]=1000.0/inDisparityValue;
    }
}
