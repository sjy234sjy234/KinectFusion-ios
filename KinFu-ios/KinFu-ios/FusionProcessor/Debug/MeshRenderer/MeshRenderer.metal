//
//  ScanningRenderer.metal
//  Scanner
//
//  Created by  沈江洋 on 23/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    float4 normal;
};

vertex Vertex meshRenderer_vertex_main(constant Vertex *vertices [[buffer(0)]],
                                        constant float4x4 &mvpTransform [[buffer(1)]],
                                        uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform * vertices[vid].position;
    vertexOut.normal = vertices[vid].normal;
    return vertexOut;
}

fragment float4 meshRenderer_fragment_main(Vertex vertexIn [[stage_in]])
{
    return vertexIn.normal/1.3;
}
