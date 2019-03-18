//
//  FuMCubeExtract.metal
//  Scanner
//
//  Created by  沈江洋 on 10/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    float4 normal;
};

struct InputFloat3
{
    float x;
    float y;
    float z;
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

struct MCubeParameter
{
    float isoValue;
    uint maxActiveNumber;
    uint minWeight;
    uint tableHeight;
    uint tableWidth;
};

// remark: vertexNumber went through a scan operation between MCubeTraverse and MCubeExtract
struct ActiveVoxelInfo
{
    uint voxelIndex;
    uint tableHeightIndex;
    uint vertexNumber;
};

struct TsdfVertex
{
    float value;
    uint weight;
};

// fuMCubeExtract compute kernel
kernel void
fuMCubeExtract(constant ActiveVoxelInfo*  inActiveVoxelInfoBuffer [[buffer(0)]],
             constant TsdfVertex*  inTsdfVertexBuffer  [[buffer(1)]],
             constant int* mCubeTriagleTable[[buffer(2)]],
             constant uint &activeVoxelNumber [[buffer(3)]],
             constant TsdfParameter &tsdfParameter[[buffer(4)]],
             constant MCubeParameter &mCubeParameter [[buffer(5)]],
             device InputFloat3*  outMCubeExtractPoints [[buffer(6)]],
             device InputFloat3*  outMCubeExtractNormals [[buffer(7)]],
             uint  gid         [[thread_position_in_grid]],
             uint  tspg        [[threads_per_grid]])
{
    
    uint invid=gid;
    if(invid<activeVoxelNumber)
    {
        uint activeVoxelIndex=inActiveVoxelInfoBuffer[invid].voxelIndex;
        uint activeTableHeightIndex=inActiveVoxelInfoBuffer[invid].tableHeightIndex;
        uint activeVertexNumber=inActiveVoxelInfoBuffer[invid].vertexNumber;
        uint resolution=tsdfParameter.resolution;
        uint planeSize=resolution*resolution;
        uint lineWidth=resolution;
        float perLength=tsdfParameter.perLength;
        float isoValue=mCubeParameter.isoValue;
        
        //align tsdf sequence for marching cube indexing
        uint tsdfPos[8];
        tsdfPos[0]=activeVoxelIndex+planeSize;  //invid001
        tsdfPos[1]=tsdfPos[0]+1;                //invid101
        tsdfPos[2]=tsdfPos[1]+lineWidth;        //invid111
        tsdfPos[3]=tsdfPos[0]+lineWidth;        //invid011
        tsdfPos[4]=tsdfPos[0]-planeSize;        //invid000
        tsdfPos[5]=tsdfPos[1]-planeSize;        //invid100
        tsdfPos[6]=tsdfPos[2]-planeSize;        //invid110
        tsdfPos[7]=tsdfPos[3]-planeSize;        //invid010

        uint voxelX=activeVoxelIndex%resolution;
        activeVoxelIndex/=resolution;
        uint voxelY=activeVoxelIndex%resolution;
        activeVoxelIndex/=resolution;
        uint voxelZ=activeVoxelIndex;
        float tsdfPosX=tsdfParameter.originX+voxelX*perLength;
        float tsdfPosY=tsdfParameter.originY+voxelY*perLength;
        float tsdfPosZ=tsdfParameter.originZ+voxelZ*perLength;
        
        //align tsdf sequence for marching cube indexing
        float4 cornerVertex[8];
        cornerVertex[0]=float4(tsdfPosX,tsdfPosY,tsdfPosZ+perLength,1.0);                      //invid001
        cornerVertex[1]=float4(tsdfPosX+perLength,tsdfPosY,tsdfPosZ+perLength,1.0);            //invid101
        cornerVertex[2]=float4(tsdfPosX+perLength,tsdfPosY+perLength,tsdfPosZ+perLength,1.0);  //invid111
        cornerVertex[3]=float4(tsdfPosX,tsdfPosY+perLength,tsdfPosZ+perLength,1.0);            //invid011
        cornerVertex[4]=float4(tsdfPosX,tsdfPosY,tsdfPosZ,1.0);                                //invid000
        cornerVertex[5]=float4(tsdfPosX+perLength,tsdfPosY,tsdfPosZ,1.0);                      //invid100
        cornerVertex[6]=float4(tsdfPosX+perLength,tsdfPosY+perLength,tsdfPosZ,1.0);            //invid110
        cornerVertex[7]=float4(tsdfPosX,tsdfPosY+perLength,tsdfPosZ,1.0);                      //invid010
        
        float tsdfValue[8];
        tsdfValue[0]=inTsdfVertexBuffer[tsdfPos[0]].value;
        tsdfValue[1]=inTsdfVertexBuffer[tsdfPos[1]].value;
        tsdfValue[2]=inTsdfVertexBuffer[tsdfPos[2]].value;
        tsdfValue[3]=inTsdfVertexBuffer[tsdfPos[3]].value;
        tsdfValue[4]=inTsdfVertexBuffer[tsdfPos[4]].value;
        tsdfValue[5]=inTsdfVertexBuffer[tsdfPos[5]].value;
        tsdfValue[6]=inTsdfVertexBuffer[tsdfPos[6]].value;
        tsdfValue[7]=inTsdfVertexBuffer[tsdfPos[7]].value;
        
        float interpRatio[12];
        interpRatio[0]=(isoValue-tsdfValue[0])/(tsdfValue[1]-tsdfValue[0]);
        interpRatio[1]=(isoValue-tsdfValue[1])/(tsdfValue[2]-tsdfValue[1]);
        interpRatio[2]=(isoValue-tsdfValue[2])/(tsdfValue[3]-tsdfValue[2]);
        interpRatio[3]=(isoValue-tsdfValue[3])/(tsdfValue[0]-tsdfValue[3]);
        interpRatio[4]=(isoValue-tsdfValue[4])/(tsdfValue[5]-tsdfValue[4]);
        interpRatio[5]=(isoValue-tsdfValue[5])/(tsdfValue[6]-tsdfValue[5]);
        interpRatio[6]=(isoValue-tsdfValue[6])/(tsdfValue[7]-tsdfValue[6]);
        interpRatio[7]=(isoValue-tsdfValue[7])/(tsdfValue[4]-tsdfValue[7]);
        interpRatio[8]=(isoValue-tsdfValue[0])/(tsdfValue[4]-tsdfValue[0]);
        interpRatio[9]=(isoValue-tsdfValue[1])/(tsdfValue[5]-tsdfValue[1]);
        interpRatio[10]=(isoValue-tsdfValue[2])/(tsdfValue[6]-tsdfValue[2]);
        interpRatio[11]=(isoValue-tsdfValue[3])/(tsdfValue[7]-tsdfValue[3]);
        
        float4 interpVertex[12];
        interpVertex[0]=(1-interpRatio[0])*cornerVertex[0]+interpRatio[0]*cornerVertex[1];
        interpVertex[1]=(1-interpRatio[1])*cornerVertex[1]+interpRatio[1]*cornerVertex[2];
        interpVertex[2]=(1-interpRatio[2])*cornerVertex[2]+interpRatio[2]*cornerVertex[3];
        interpVertex[3]=(1-interpRatio[3])*cornerVertex[3]+interpRatio[3]*cornerVertex[0];
        interpVertex[4]=(1-interpRatio[4])*cornerVertex[4]+interpRatio[4]*cornerVertex[5];
        interpVertex[5]=(1-interpRatio[5])*cornerVertex[5]+interpRatio[5]*cornerVertex[6];
        interpVertex[6]=(1-interpRatio[6])*cornerVertex[6]+interpRatio[6]*cornerVertex[7];
        interpVertex[7]=(1-interpRatio[7])*cornerVertex[7]+interpRatio[7]*cornerVertex[4];
        interpVertex[8]=(1-interpRatio[8])*cornerVertex[0]+interpRatio[8]*cornerVertex[4];
        interpVertex[9]=(1-interpRatio[9])*cornerVertex[1]+interpRatio[9]*cornerVertex[5];
        interpVertex[10]=(1-interpRatio[10])*cornerVertex[2]+interpRatio[10]*cornerVertex[6];
        interpVertex[11]=(1-interpRatio[11])*cornerVertex[3]+interpRatio[11]*cornerVertex[7];
        
        uint outvidstart=0;
        if(invid>0)
        {
            outvidstart=inActiveVoxelInfoBuffer[invid-1].vertexNumber;
        }
        uint outvidEnd=inActiveVoxelInfoBuffer[invid].vertexNumber;
        uint tableIndexStart=activeTableHeightIndex*16;
        for(int i=outvidstart;i<outvidEnd;++i)
        {
            uint offset=i-outvidstart;
            uint tableIndex=tableIndexStart+offset;
            uint index=mCubeTriagleTable[tableIndex];
            outMCubeExtractPoints[i] = {interpVertex[index].x, interpVertex[index].y, interpVertex[index].z};
            if(offset%3==2)
            {
                float3 edge0=float3(outMCubeExtractPoints[i-1].x, outMCubeExtractPoints[i-1].y, outMCubeExtractPoints[i-1].z)-float3(outMCubeExtractPoints[i-2].x, outMCubeExtractPoints[i-2].y, outMCubeExtractPoints[i-2].z);
                float3 edge1=float3(outMCubeExtractPoints[i].x, outMCubeExtractPoints[i].y, outMCubeExtractPoints[i].z)-float3(outMCubeExtractPoints[i-2].x, outMCubeExtractPoints[i-2].y, outMCubeExtractPoints[i-2].z);
                float4 normal=float4(normalize(cross(edge0,edge1)),1.0);
                outMCubeExtractNormals[i - 2] = {normal.x, normal.y, normal.z};
                outMCubeExtractNormals[i - 1] = {normal.x, normal.y, normal.z};
                outMCubeExtractNormals[i] = {normal.x, normal.y, normal.z};
            }
        }
    }
}
