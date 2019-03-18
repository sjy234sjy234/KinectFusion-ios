//
//  PointRendererEncoder.metal
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/8.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
using namespace metal;

struct Vertex{
    float4 position [[position]];
    float size[[point_size]];
    half4 color;
};

struct InputFloat3
{
    float x;
    float y;
    float z;
};

struct PointSize
{
    float val;
};

struct PointColor
{
    float4 val;
};

struct MvpTransform
{
    float4x4 val;
};

vertex Vertex pointRenderer_vertex_main(constant InputFloat3 *vertices [[buffer(0)]],
                                        constant PointSize *pointSize [[buffer(1)]],
                                        constant PointColor *pointColor [[buffer(2)]],
                                        constant MvpTransform *mvpTransform [[buffer(3)]],
                                        uint vid [[vertex_id]])
{
    Vertex outVertex;
    outVertex.position = mvpTransform->val * float4(vertices[vid].x, vertices[vid].y, vertices[vid].z, 1.0);
    outVertex.size = pointSize->val;
    outVertex.color = (half4)(pointColor->val);
    
    outVertex.position = outVertex.position / outVertex.position.w;
    outVertex.position.z -= 0.01;
    return outVertex;
}

fragment half4 pointRenderer_fragment_main(Vertex inVertex [[stage_in]])
{
    return inVertex.color;
}


