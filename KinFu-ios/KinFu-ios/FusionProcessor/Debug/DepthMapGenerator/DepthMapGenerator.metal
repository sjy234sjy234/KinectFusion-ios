//
//  DepthMapGenerator.metal
//  Scanner
//
//  Created by  沈江洋 on 11/03/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct CameraNDC2Depth
{
    float param1;
    float param2;
};

// depthMapGenerator compute kernel
kernel void
depthMapGenerator(constant half*  currentDisparityBuffer  [[buffer(0)]],
                    device float* currentDepthMapBuffer0  [[buffer(1)]],
                    device float* currentDepthMapBuffer1  [[buffer(2)]],
                    device float* currentDepthMapBuffer2  [[buffer(3)]],
                  texture2d<float, access::read> preDepthTexture [[texture(0)]],
                  device float*  preDepthMap0  [[buffer(4)]],
                  device float*  preDepthMap1  [[buffer(5)]],
                  device float*  preDepthMap2  [[buffer(6)]],
                  constant CameraNDC2Depth&  cameraFrustum  [[buffer(7)]],
                    uint2  gid         [[thread_position_in_grid]],
                    uint2  tspg        [[threads_per_grid]])
{
    uint width=tspg.x;
    
    uint outvid0=gid.y*width+gid.x;
    uint invid00=outvid0;
    half currentDisparityValue00 = currentDisparityBuffer[invid00];
    if(currentDisparityValue00<=0.0)
    {
        //for invalid disparity data, set depth map to -1.0
        currentDepthMapBuffer0[outvid0]=-1.0;
        
    }
    else
    {
        currentDepthMapBuffer0[outvid0]=1000.0/currentDisparityValue00;
    }
    uint2 ingid00=gid;
    float ndcDepth00 = preDepthTexture.read(ingid00).x;
    if(ndcDepth00>=0.999)
    {
        preDepthMap0[outvid0]=-1.0;
    }
    else
    {
        float depth00=cameraFrustum.param1/(ndcDepth00+cameraFrustum.param2);
        preDepthMap0[outvid0]=depth00;
    }
    
    if(gid.x%2==0&&gid.y%2==0)
    {
        uint outvid1=gid.y*width/4+gid.x/2;
        
        uint invid01=invid00+width;
        uint invid10=invid00+1;
        uint invid11=invid01+1;
        half currentDisparityValue01 = currentDisparityBuffer[invid01];
        half currentDisparityValue10 = currentDisparityBuffer[invid10];
        half currentDisparityValue11 = currentDisparityBuffer[invid11];
        if(currentDisparityValue00<=0||currentDisparityValue01<=0||currentDisparityValue10<=0||currentDisparityValue11<=0)
        {
            currentDepthMapBuffer1[outvid1]=-1.0;
        }
        else
        {
            currentDepthMapBuffer1[outvid1]=4000.0/(currentDisparityValue00+currentDisparityValue01+currentDisparityValue10+currentDisparityValue11);
        }
        
        uint2 ingid01=uint2(gid.x,gid.y+1);
        uint2 ingid10=uint2(gid.x+1,gid.y);
        uint2 ingid11=uint2(gid.x+1,gid.y+1);
        float ndcDepth10 = preDepthTexture.read(ingid10).x;
        float ndcDepth01 = preDepthTexture.read(ingid01).x;
        float ndcDepth11 = preDepthTexture.read(ingid11).x;
        if(ndcDepth00>=0.999||ndcDepth01>=0.999||ndcDepth10>=0.999||ndcDepth11>=0.999)
        {
            preDepthMap1[outvid1]=-1.0;
        }
        else
        {
            float depth00=cameraFrustum.param1/(ndcDepth00+cameraFrustum.param2);
            float depth01=cameraFrustum.param1/(ndcDepth01+cameraFrustum.param2);
            float depth10=cameraFrustum.param1/(ndcDepth10+cameraFrustum.param2);
            float depth11=cameraFrustum.param1/(ndcDepth11+cameraFrustum.param2);
            preDepthMap1[outvid1]=(depth00+depth01+depth10+depth11)/4.0;
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
            half currentDisparityValue02 = currentDisparityBuffer[invid02];
            half currentDisparityValue03 = currentDisparityBuffer[invid03];
            half currentDisparityValue12 = currentDisparityBuffer[invid12];
            half currentDisparityValue13 = currentDisparityBuffer[invid13];
            half currentDisparityValue20 = currentDisparityBuffer[invid20];
            half currentDisparityValue21 = currentDisparityBuffer[invid21];
            half currentDisparityValue22 = currentDisparityBuffer[invid22];
            half currentDisparityValue23 = currentDisparityBuffer[invid23];
            half currentDisparityValue30 = currentDisparityBuffer[invid30];
            half currentDisparityValue31 = currentDisparityBuffer[invid31];
            half currentDisparityValue32 = currentDisparityBuffer[invid32];
            half currentDisparityValue33 = currentDisparityBuffer[invid33];
            if(currentDisparityValue00<=0||currentDisparityValue01<=0||currentDisparityValue02<=0||currentDisparityValue03<=0
               ||currentDisparityValue10<=0||currentDisparityValue11<=0||currentDisparityValue12<=0||currentDisparityValue13<=0
               ||currentDisparityValue20<=0||currentDisparityValue21<=0||currentDisparityValue22<=0||currentDisparityValue23<=0
               ||currentDisparityValue30<=0||currentDisparityValue31<=0||currentDisparityValue32<=0||currentDisparityValue33<=0)
            {
                currentDepthMapBuffer2[outvid2]=-1.0;
            }
            else
            {
                currentDepthMapBuffer2[outvid2]=16000.0/(currentDisparityValue00+currentDisparityValue01+currentDisparityValue02+currentDisparityValue03+
                                                     currentDisparityValue10+currentDisparityValue11+currentDisparityValue12+currentDisparityValue13+
                                                     currentDisparityValue20+currentDisparityValue21+currentDisparityValue22+currentDisparityValue23+
                                                     currentDisparityValue30+currentDisparityValue31+currentDisparityValue32+currentDisparityValue33);
            }
            
            uint2 ingid02=uint2(gid.x,gid.y+2);
            uint2 ingid03=uint2(gid.x,gid.y+3);
            uint2 ingid12=uint2(gid.x+1,gid.y+2);
            uint2 ingid13=uint2(gid.x+1,gid.y+3);
            uint2 ingid20=uint2(gid.x+2,gid.y);
            uint2 ingid21=uint2(gid.x+2,gid.y+1);
            uint2 ingid22=uint2(gid.x+2,gid.y+2);
            uint2 ingid23=uint2(gid.x+2,gid.y+3);
            uint2 ingid30=uint2(gid.x+3,gid.y);
            uint2 ingid31=uint2(gid.x+3,gid.y+1);
            uint2 ingid32=uint2(gid.x+3,gid.y+2);
            uint2 ingid33=uint2(gid.x+3,gid.y+3);
            float ndcDepth20 = preDepthTexture.read(ingid20).x;
            float ndcDepth30 = preDepthTexture.read(ingid30).x;
            float ndcDepth21 = preDepthTexture.read(ingid21).x;
            float ndcDepth31 = preDepthTexture.read(ingid31).x;
            float ndcDepth02 = preDepthTexture.read(ingid02).x;
            float ndcDepth12 = preDepthTexture.read(ingid12).x;
            float ndcDepth22 = preDepthTexture.read(ingid22).x;
            float ndcDepth32 = preDepthTexture.read(ingid32).x;
            float ndcDepth03 = preDepthTexture.read(ingid03).x;
            float ndcDepth13 = preDepthTexture.read(ingid13).x;
            float ndcDepth23 = preDepthTexture.read(ingid23).x;
            float ndcDepth33 = preDepthTexture.read(ingid33).x;
            if(ndcDepth00>=0.999||ndcDepth01>=0.999||ndcDepth02>=0.999||ndcDepth03>=0.999
               ||ndcDepth10>=0.999||ndcDepth11>=0.999||ndcDepth12>=0.999||ndcDepth13>=0.999
               ||ndcDepth20>=0.999||ndcDepth21>=0.999||ndcDepth22>=0.999||ndcDepth23>=0.999
               ||ndcDepth30>=0.999||ndcDepth31>=0.999||ndcDepth32>=0.999||ndcDepth33>=0.999)
            {
                preDepthMap2[outvid2]=-1.0;
            }
            else
            {
                float depth00=cameraFrustum.param1/(ndcDepth00+cameraFrustum.param2);
                float depth01=cameraFrustum.param1/(ndcDepth01+cameraFrustum.param2);
                float depth02=cameraFrustum.param1/(ndcDepth02+cameraFrustum.param2);
                float depth03=cameraFrustum.param1/(ndcDepth03+cameraFrustum.param2);
                float depth10=cameraFrustum.param1/(ndcDepth10+cameraFrustum.param2);
                float depth11=cameraFrustum.param1/(ndcDepth11+cameraFrustum.param2);
                float depth12=cameraFrustum.param1/(ndcDepth12+cameraFrustum.param2);
                float depth13=cameraFrustum.param1/(ndcDepth13+cameraFrustum.param2);
                float depth20=cameraFrustum.param1/(ndcDepth20+cameraFrustum.param2);
                float depth21=cameraFrustum.param1/(ndcDepth21+cameraFrustum.param2);
                float depth22=cameraFrustum.param1/(ndcDepth22+cameraFrustum.param2);
                float depth23=cameraFrustum.param1/(ndcDepth23+cameraFrustum.param2);
                float depth30=cameraFrustum.param1/(ndcDepth30+cameraFrustum.param2);
                float depth31=cameraFrustum.param1/(ndcDepth31+cameraFrustum.param2);
                float depth32=cameraFrustum.param1/(ndcDepth32+cameraFrustum.param2);
                float depth33=cameraFrustum.param1/(ndcDepth33+cameraFrustum.param2);
                preDepthMap2[outvid2]=(depth00+depth01+depth02+depth03
                                       +depth10+depth11+depth12+depth13
                                       +depth20+depth21+depth22+depth23
                                       +depth30+depth31+depth32+depth33)/16.0;
            }
        }
        
    }
    
}
