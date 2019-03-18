//
//  FuMCubeTraverse.metal
//  Scanner
//
//  Created by  沈江洋 on 10/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.!
//

#include <metal_stdlib>
using namespace metal;

struct TsdfVertex
{
    float value;
    uint weight;
};

struct MCubeParameter
{
    float isoValue;
    uint maxActiveNumber;
    uint minWeight;
    uint tableHeight;
    uint tableWidth;
};

struct ActiveVoxelInfo
{
    uint voxelIndex;
    uint tableHeightIndex;
    uint vertexNumber;
};

// fuMCubeTraverse compute kernel
kernel void
fuMCubeTraverse(constant TsdfVertex*  inTsdfVertexBuffer  [[buffer(0)]],
                  device ActiveVoxelInfo*  outActiveVoxelInfoBuffer [[buffer(1)]],
                  constant uint* mCubeNumVertsTable[[buffer(2)]],
                  constant MCubeParameter &mCubeParameter [[buffer(3)]],
                  device atomic_uint &activeVoxelNumber [[buffer(4)]],
                  uint3  gid         [[thread_position_in_grid]],
                  uint3  tspg        [[threads_per_grid]])
{
    
    if(gid.x>=tspg.x-1||gid.y>=tspg.y-1||gid.z>=tspg.z-1)
    {
        return;
    }

    uint planeSize=tspg.x*tspg.y;
    uint lineWidth=tspg.x;

    //align tsdf sequence for marching cube indexing
    uint invid[8];
    invid[0]=(gid.z+1)*planeSize+gid.y*lineWidth+gid.x;  //invid001
    invid[1]=invid[0]+1;                                 //invid101
    invid[2]=invid[1]+lineWidth;                         //invid111
    invid[3]=invid[0]+lineWidth;                         //invid011
    invid[4]=invid[0]-planeSize;                         //invid000
    invid[5]=invid[1]-planeSize;                         //invid100
    invid[6]=invid[2]-planeSize;                         //invid110
    invid[7]=invid[3]-planeSize;                         //invid010
    
    float minWeight=mCubeParameter.minWeight;
    float field[8];
    for(int i=0;i<8;++i)
    {
        TsdfVertex tsdfVertex=inTsdfVertexBuffer[invid[i]];
        field[i]=tsdfVertex.value*(tsdfVertex.weight>=minWeight);
        if(field[i]==0.0)
        {
            return;
        }
    }

    float isoValue=mCubeParameter.isoValue;
    int tableHeightIndex = 0;
    tableHeightIndex|=(int(field[0]<isoValue)<<0);
    tableHeightIndex|=(int(field[1]<isoValue)<<1);
    tableHeightIndex|=(int(field[2]<isoValue)<<2);
    tableHeightIndex|=(int(field[3]<isoValue)<<3);
    tableHeightIndex|=(int(field[4]<isoValue)<<4);
    tableHeightIndex|=(int(field[5]<isoValue)<<5);
    tableHeightIndex|=(int(field[6]<isoValue)<<6);
    tableHeightIndex|=(int(field[7]<isoValue)<<7);
    if(mCubeNumVertsTable[tableHeightIndex]==0)
    {
        return;
    }

    uint lastActiveIndexVid =atomic_fetch_add_explicit( &activeVoxelNumber, 1, memory_order_relaxed );
    if(lastActiveIndexVid<mCubeParameter.maxActiveNumber)
    {
        outActiveVoxelInfoBuffer[lastActiveIndexVid].voxelIndex=invid[4];
        outActiveVoxelInfoBuffer[lastActiveIndexVid].tableHeightIndex=tableHeightIndex;
        outActiveVoxelInfoBuffer[lastActiveIndexVid].vertexNumber=mCubeNumVertsTable[tableHeightIndex];
    }
}
