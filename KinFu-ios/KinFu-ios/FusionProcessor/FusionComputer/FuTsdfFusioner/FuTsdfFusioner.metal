//
//  FuTsdfFusioner.metal
//  Scanner
//
//  Created by  沈江洋 on 07/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct TsdfVertex
{
    float value;
    uint weight;
};

struct IntrinsicXYZ2UVD
{
    float focal;
    float centerU;
    float centerV;
};

struct TsdfParameter
{
    float originX;
    float originY;
    float originZ;
    float perLength;
    float truncate;
    uint maxWeight;
    uint resolution;
};

// fuTsdfFusioner compute kernel
kernel void
fuTsdfFusioner(constant float*  inDepthMap  [[buffer(0)]],
              device TsdfVertex*  outTsdfVertexBuffer [[buffer(1)]],
              constant int2 &depthMapSize [[buffer(2)]],
               constant IntrinsicXYZ2UVD &intrinsic_XYZ2UVD [[buffer(3)]],
              constant TsdfParameter &tsdfParameter[[buffer(4)]],
              constant float4x4 &globalToFrameTransformBuffer[[buffer(5)]],
                 uint3  gid         [[thread_position_in_grid]],
                 uint3  tspg        [[threads_per_grid]])
{
    //from tsdf pos ijk to global pos xyz
    float tsdfGlobalPosX=tsdfParameter.originX+gid.x*tsdfParameter.perLength;
    float tsdfGlobalPosY=tsdfParameter.originY+gid.y*tsdfParameter.perLength;
    float tsdfGlobalPosZ=tsdfParameter.originZ+gid.z*tsdfParameter.perLength;
    float4 tsdfGlobalPos(tsdfGlobalPosX,tsdfGlobalPosY,tsdfGlobalPosZ,1.0);
    float4 tsdfFramePos=globalToFrameTransformBuffer*tsdfGlobalPos;

    //from global pos xyz to depth map pos uvd
    float d= -tsdfFramePos.z;
    int u= round(tsdfFramePos.x*intrinsic_XYZ2UVD.focal/d+intrinsic_XYZ2UVD.centerU);
    int v= round(-tsdfFramePos.y*intrinsic_XYZ2UVD.focal/d+intrinsic_XYZ2UVD.centerV);

    //update tsdf vertex
    if(u<0||u>=depthMapSize.x||v<0||v>=depthMapSize.y)
    {
        return;
    }
    uint invid=v*depthMapSize.x+u;
    float zValueFromMap=-inDepthMap[invid];
    if(zValueFromMap>=0.0)
    {
        return;
    }
    uint outvid=gid.z*(tspg.x*tspg.y)+gid.y*tspg.x+gid.x;
    float zValueFromTsdf=tsdfFramePos.z;
    float sdfValue=zValueFromTsdf-zValueFromMap;
    if(sdfValue>=-tsdfParameter.truncate)
    {
        float tsdfValue=min(1.0, sdfValue/tsdfParameter.truncate);
        TsdfVertex oldTsdfVertex=outTsdfVertexBuffer[outvid];
        outTsdfVertexBuffer[outvid].value=(oldTsdfVertex.value*oldTsdfVertex.weight+tsdfValue)/(oldTsdfVertex.weight+1.0);
        outTsdfVertexBuffer[outvid].weight=min(oldTsdfVertex.weight+1,tsdfParameter.maxWeight);
    }
    
}

