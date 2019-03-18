//
//  MapErrorVisualizer.metal
//  Scanner
//
//  Created by  沈江洋 on 13/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// mapErrorVisualizer compute kernel
kernel void
mapErrorVisualizer(constant float*  firstMapBuffer  [[buffer(0)]],
                   constant float*  secondMapBuffer  [[buffer(1)]],
                  texture2d<half, access::write> outErrorTexture [[texture(0)]],
                  uint2  gid         [[thread_position_in_grid]],
                  uint2  tspg        [[threads_per_grid]])
{
    uint vid=gid.y*tspg.x+gid.x;
    float firstMapValue  = firstMapBuffer[vid];
    float secondMapValue  = secondMapBuffer[vid];
    float error=abs(secondMapValue-firstMapValue);
    if(firstMapValue<=0.0||secondMapValue<=0.0)
    {
        outErrorTexture.write(half4(1.0, 1.0, 1.0, 1.0), gid);
    }
    else if(error>1.0)
    {
        outErrorTexture.write(half4(1.0, 0.0, 0.0, 1.0), gid);
    }
    else
    {
        
        outErrorTexture.write(half4(error, error, error, 1.0), gid);
    }
    
}
