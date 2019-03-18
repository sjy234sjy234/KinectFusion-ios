//
//  TextureRendererEncoder.m
//  Learn-Metal
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import "TextureRendererEncoder.h"
#import "MathUtilities.hpp"

@interface TextureRendererEncoder ()
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLSamplerState> samplerState;
@property (nonatomic, strong) id<MTLRenderPipelineState> textureRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> textureVertexBuffer;

@end

@implementation TextureRendererEncoder

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
        [self buildResources];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    id<MTLFunction> textureVertexFunc = [library newFunctionWithName:@"texture_vertex_main"];
    id<MTLFunction> textureFragmentFunc = [library newFunctionWithName:@"texture_fragment_main"];
    
    MTLRenderPipelineDescriptor *texturePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    texturePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    texturePipelineDescriptor.vertexFunction = textureVertexFunc;
    texturePipelineDescriptor.fragmentFunction = textureFragmentFunc;
    
    _textureRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:texturePipelineDescriptor
                                                                                  error:&error];
    
    if (!_textureRenderPipeline)
    {
        NSLog(@"Error occurred when creating texture render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    const TextureVertex textureVertices[] =
    {
        { .position = { -1.0, -1.0, 0, 1 }, .texCoords = { 0.0, 1.0 } },
        { .position = { -1.0,  1.0, 0, 1 }, .texCoords = { 0.0, 0.0 } },
        { .position = {  1.0, -1.0, 0, 1 }, .texCoords = { 1.0, 1.0 } },
        { .position = {  1.0,  1.0, 0, 1 }, .texCoords = { 1.0, 0.0 } }
    };
    _textureVertexBuffer = [_metalContext.device newBufferWithBytes:textureVertices
                                                             length:sizeof(textureVertices)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
    _samplerState = [_metalContext.device newSamplerStateWithDescriptor:samplerDesc];
}

- (void)setQuadVertex: (const float *)quadVertex
{
    if(quadVertex)
    {
        const TextureVertex textureVertices[] =
        {
            { .position = { quadVertex[0], quadVertex[1], quadVertex[2], 1 }, .texCoords = { 0.0, 1.0 } },
            { .position = { quadVertex[3], quadVertex[4], quadVertex[5], 1 }, .texCoords = { 0.0, 0.0 } },
            { .position = { quadVertex[6], quadVertex[7], quadVertex[8], 1 }, .texCoords = { 1.0, 1.0 } },
            { .position = { quadVertex[9], quadVertex[10], quadVertex[11], 1 }, .texCoords = { 1.0, 0.0 } }
        };
        _textureVertexBuffer = [_metalContext.device newBufferWithBytes:textureVertices
                                                                 length:sizeof(textureVertices)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    }
}

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer sourceTexture: (id<MTLTexture>) inTexture destinationTexture: (id<MTLTexture>) outTexture
{
    if(!commandBuffer)
    {
        NSLog(@"invalid command buffer");
        return ;
    }
    
    if(!inTexture || !outTexture)
    {
        NSLog(@"invalid texture");
        return ;
    }
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = outTexture;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    [renderEncoder setRenderPipelineState:_textureRenderPipeline];
    [renderEncoder setFragmentTexture:inTexture atIndex:0];
    [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
    [renderEncoder setVertexBuffer: _textureVertexBuffer offset:0 atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:1 vertexCount:3];
    [renderEncoder endEncoding];
}

@end
