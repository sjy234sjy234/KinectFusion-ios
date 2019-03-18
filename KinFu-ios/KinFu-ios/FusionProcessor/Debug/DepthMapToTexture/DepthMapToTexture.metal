//
//  MetalDepthMapToTexture.metal
//  Scanner
//
//  Created by  沈江洋 on 03/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// depthMapToTexture compute kernel
kernel void
depthMapToTexture(constant float*  inDepthMap  [[buffer(0)]],
                  texture2d<half, access::write> outTexture [[texture(0)]],
                  uint2  gid         [[thread_position_in_grid]],
                  uint2  tspg        [[threads_per_grid]])
{
    uint vid=gid.y*tspg.x+gid.x;
    float inDepthValue  = inDepthMap[vid];
    inDepthValue=inDepthValue/1000.0;
    //test if it is a valid depth data
    if(inDepthValue<=0.0)
    {
        outTexture.write(half4(1.0, 0.0, 0.0, 1.0), gid);
    }
    else
    {
        outTexture.write(half4(inDepthValue, inDepthValue, inDepthValue, 1.0), gid);
    }
}
