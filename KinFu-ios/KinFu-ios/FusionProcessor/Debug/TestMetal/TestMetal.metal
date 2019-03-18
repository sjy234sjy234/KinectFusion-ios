//
//  TestMetal.metal
//  Scanner
//
//  Created by  沈江洋 on 09/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// testMetal compute kernel
kernel void
testMetal(device float*  inBuffer  [[buffer(0)]],
                 device float*  outBuffer [[buffer(1)]],
                 device atomic_uint &testData [[buffer(2)]],
                 uint2  gid         [[thread_position_in_grid]],
                 uint2  tspg        [[threads_per_grid]])
{
    uint vid=gid.y*tspg.x+gid.x;
    inBuffer[vid]=atomic_fetch_add_explicit( &testData, 1, memory_order_relaxed );
    outBuffer[vid]=gid.y;
    
    
}
