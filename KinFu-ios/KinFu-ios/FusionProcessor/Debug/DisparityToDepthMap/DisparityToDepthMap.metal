//
//  DisparityToDepthMap.metal
//  Scanner
//
//  Created by  沈江洋 on 18/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// disparityToDepthMap compute kernel
kernel void
disparityToDepthMap(constant half*  inDisparityBuffer  [[buffer(0)]],
                    device float* outDepthMapBuffer0  [[buffer(1)]],
                    device float* outDepthMapBuffer1  [[buffer(2)]],
                    device float* outDepthMapBuffer2  [[buffer(3)]],
                    uint2  gid         [[thread_position_in_grid]],
                    uint2  tspg        [[threads_per_grid]])
{
    uint width=tspg.x;
    
    uint invid00=gid.y*width+gid.x;
    half inDisparityValue00 = inDisparityBuffer[invid00];
    uint outvid0=invid00;
    if(inDisparityValue00<=0.0)
    {
        //for invalid disparity data, set depth map to -1.0
        outDepthMapBuffer0[outvid0]=-1.0;
    }
    else
    {
        outDepthMapBuffer0[outvid0]=1000.0/inDisparityValue00;
    }
    
    if(gid.x%2==0&&gid.y%2==0)
    {
        uint outvid1=gid.y*width/4+gid.x/2;
        
        uint invid01=invid00+width;
        uint invid10=invid00+1;
        uint invid11=invid01+1;
        half inDisparityValue01 = inDisparityBuffer[invid01];
        half inDisparityValue10 = inDisparityBuffer[invid10];
        half inDisparityValue11 = inDisparityBuffer[invid11];
        
        if(inDisparityValue00<=0||inDisparityValue01<=0||inDisparityValue10<=0||inDisparityValue11<=0)
        {
            outDepthMapBuffer1[outvid1]=-1.0;
        }
        else
        {
            outDepthMapBuffer1[outvid1]=4000.0/(inDisparityValue00+inDisparityValue01+inDisparityValue10+inDisparityValue11);
        }
        
        if(gid.x%4==0&&gid.y%4==0)
        {
            uint outvid2=gid.y*width/16+gid.x/4;
            
            uint invid02=invid01+width;
            uint invid03=invid02+width;
            uint invid12=invid02+1;
            uint invid13=invid03+1;
            uint invid20=invid10+1;
            uint invid21=invid11+1;
            uint invid22=invid12+1;
            uint invid23=invid13+1;
            uint invid30=invid20+1;
            uint invid31=invid21+1;
            uint invid32=invid22+1;
            uint invid33=invid23+1;
            
            half inDisparityValue02 = inDisparityBuffer[invid02];
            half inDisparityValue03 = inDisparityBuffer[invid03];
            half inDisparityValue12 = inDisparityBuffer[invid12];
            half inDisparityValue13 = inDisparityBuffer[invid13];
            half inDisparityValue20 = inDisparityBuffer[invid20];
            half inDisparityValue21 = inDisparityBuffer[invid21];
            half inDisparityValue22 = inDisparityBuffer[invid22];
            half inDisparityValue23 = inDisparityBuffer[invid23];
            half inDisparityValue30 = inDisparityBuffer[invid30];
            half inDisparityValue31 = inDisparityBuffer[invid31];
            half inDisparityValue32 = inDisparityBuffer[invid32];
            half inDisparityValue33 = inDisparityBuffer[invid33];
            
            if(inDisparityValue00<=0||inDisparityValue01<=0||inDisparityValue02<=0||inDisparityValue03<=0
               ||inDisparityValue10<=0||inDisparityValue11<=0||inDisparityValue12<=0||inDisparityValue13<=0
               ||inDisparityValue20<=0||inDisparityValue21<=0||inDisparityValue22<=0||inDisparityValue23<=0
               ||inDisparityValue30<=0||inDisparityValue31<=0||inDisparityValue32<=0||inDisparityValue33<=0)
            {
                outDepthMapBuffer2[outvid2]=-1.0;
            }
            else
            {
                outDepthMapBuffer2[outvid2]=16000.0/(inDisparityValue00+inDisparityValue01+inDisparityValue02+inDisparityValue03+
                                                     inDisparityValue10+inDisparityValue11+inDisparityValue12+inDisparityValue13+
                                                     inDisparityValue20+inDisparityValue21+inDisparityValue22+inDisparityValue23+
                                                     inDisparityValue30+inDisparityValue31+inDisparityValue32+inDisparityValue33);
            }
        }
        
    }
    
}
