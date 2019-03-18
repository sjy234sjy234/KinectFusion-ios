#include <metal_stdlib>

using namespace metal;

struct TextureVertex
{
    float4 position [[position]];
    float2 texCoords;
};

vertex TextureVertex texture_vertex_main(constant TextureVertex *vertices [[buffer(0)]],
                                      uint vid [[vertex_id]])
{
    return vertices[vid];
}

fragment half4 texture_fragment_main(TextureVertex vert [[stage_in]],
                                 texture2d<float> videoTexture [[texture(0)]],
                                 sampler samplr [[sampler(0)]])
{
    float4 texColor = float4(videoTexture.sample(samplr, vert.texCoords).rgb, 1);
    return (half4)texColor;
}
