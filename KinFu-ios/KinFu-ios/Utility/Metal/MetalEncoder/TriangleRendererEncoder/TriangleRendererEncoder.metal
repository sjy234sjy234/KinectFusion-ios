//
//  TriangleRendererEncoder.metal
//  Scanner
//
//  Created by  沈江洋 on 2018/9/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    half4 normal;
};

struct InputFloat3
{
    float x;
    float y;
    float z;
};

vertex Vertex triangle_vertex_main(constant InputFloat3 *vertices [[buffer(0)]],
                                      constant InputFloat3 *normals [[buffer(1)]],
                                      constant float4x4 &mvpTransform [[buffer(2)]],
                                      uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform * float4(vertices[vid].x, vertices[vid].y, vertices[vid].z, 1.0);
    float4 normal = normalize(float4((half)normals[vid].x, (half)normals[vid].y, (half)normals[vid].z, 1.0));
    vertexOut.normal = (half4)normal;
    return vertexOut;
}

fragment half4 triangle_fragment_main(Vertex vertexIn [[stage_in]])
{
    return (vertexIn.normal + 1.0) / 2.0;
//    return vertexIn.normal;
}

