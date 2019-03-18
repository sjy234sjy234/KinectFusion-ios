//
//  FuMeshToTexture.metal
//  Scanner
//
//  Created by  沈江洋 on 12/01/2018.
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

vertex Vertex fuMeshToTexture_vertex_main(constant InputFloat3* verticesT [[buffer(0)]],
                                        constant InputFloat3* normalsT [[buffer(1)]],
                                        constant float4x4 &mvpTransform [[buffer(2)]],
                                        uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform * float4(verticesT[vid].x, verticesT[vid].y, verticesT[vid].z, 1.0);
    vertexOut.normal = float4(normalsT[vid].x, normalsT[vid].y, normalsT[vid].z, 1.0);
    return vertexOut;
}

fragment float4 fuMeshToTexture_fragment_main(Vertex vertexIn [[stage_in]])
{
    return (vertexIn.normal+1.0)/2.6;
}

