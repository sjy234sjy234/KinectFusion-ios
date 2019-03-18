//
//  FuTextureToDepth.metal
//  Scanner
//
//  Created by  沈江洋 on 13/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct CameraNDC2Depth
{
    float param1;
    float param2;
};

// fuTextureToDepth compute kernel
kernel void
fuTextureToDepth(texture2d<float, access::read> inDepthTexture [[texture(0)]],
                  device float*  outDepthMap  [[buffer(0)]],
                  constant CameraNDC2Depth&  cameraFrustum  [[buffer(1)]],
                  uint2  gid         [[thread_position_in_grid]],
                  uint2  tspg        [[threads_per_grid]])
{
    uint vid=gid.y*tspg.x+gid.x;
    float ndcDepth=inDepthTexture.read(gid).x;
    if(ndcDepth>=0.999)
    {
        outDepthMap[vid]=-1.0;
    }
    else
    {
        outDepthMap[vid]=cameraFrustum.param1/(ndcDepth+cameraFrustum.param2);
    }
}
