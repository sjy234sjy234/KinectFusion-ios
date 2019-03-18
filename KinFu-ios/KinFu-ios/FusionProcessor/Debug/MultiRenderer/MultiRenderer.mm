//
//  MuiltiRenderer.m
//  Scanner
//
//  Created by  沈江洋 on 23/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "MultiRenderer.h"

typedef struct
{
    simd::float4 position;
    simd::float2 texCoords;
} TextureVertex;

@interface MultiRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLSamplerState> samplerState;
@property (nonatomic, strong) id<MTLRenderPipelineState> textureRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> videoTextureVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> meshTextureVertexBuffer;

@end

@implementation MultiRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
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
    
    id<MTLFunction> multiVertexFunc = [library newFunctionWithName:@"multiRenderer_vertex_main"];
    id<MTLFunction> multiFragmentFunc = [library newFunctionWithName:@"multiRenderer_fragment_main"];
    
    MTLRenderPipelineDescriptor *texturePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    texturePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    texturePipelineDescriptor.vertexFunction = multiVertexFunc;
    texturePipelineDescriptor.fragmentFunction = multiFragmentFunc;
    
    _textureRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:texturePipelineDescriptor
                                                                                error:&error];
    
    if (!_textureRenderPipeline)
    {
        NSLog(@"Error occurred when creating multi render pipeline state: %@", error);
    }
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
    _samplerState = [_metalContext.device newSamplerStateWithDescriptor:samplerDesc];
}

- (void)buildResources
{
    static const TextureVertex videoTextureVertices[] =
    {
        { .position = { -1.0, -1.0, 0, 1 }, .texCoords = { 0.0, 1.0 } },
        { .position = { -1.0,  1.0, 0, 1 }, .texCoords = { 0.0, 0.0 } },
        { .position = {  1.0, -1.0, 0, 1 }, .texCoords = { 1.0, 1.0 } },
        { .position = {  1.0,  1.0, 0, 1 }, .texCoords = { 1.0, 0.0 } }
    };
    _videoTextureVertexBuffer = [_metalContext.device newBufferWithBytes:videoTextureVertices
                                                                 length:sizeof(videoTextureVertices)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    
    static const TextureVertex meshTextureVertices[] =
    {
        { .position = { -1.0, -1.0, 0, 1 }, .texCoords = { 0.0, 1.0 } },
        { .position = { -1.0, -0.3, 0, 1 }, .texCoords = { 0.0, 0.0 } },
        { .position = { -0.3, -1.0, 0, 1 }, .texCoords = { 1.0, 1.0 } },
        { .position = { -0.3, -0.3, 0, 1 }, .texCoords = { 1.0, 0.0 } }
    };
    _meshTextureVertexBuffer = [_metalContext.device newBufferWithBytes:meshTextureVertices
                                                           length:sizeof(meshTextureVertices)
                                                          options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)drawVideoTexture: (id<MTLTexture>) inVideoTexture andMeshTexture: (id<MTLTexture>) inMeshTexture
{
    if(!inVideoTexture&&!inMeshTexture)
    {
        return;
    }
    
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    if (drawable)
    {
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"MultiRendererCommand";
        
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 1.0, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        if(inVideoTexture)
        {
            [renderEncoder setRenderPipelineState:_textureRenderPipeline];
            [renderEncoder setFragmentTexture:inVideoTexture atIndex:0];
            [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
            [renderEncoder setVertexBuffer:_videoTextureVertexBuffer offset:0 atIndex:0];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:1 vertexCount:3];
        }
        
        if(inMeshTexture)
        {
            [renderEncoder setRenderPipelineState:_textureRenderPipeline];
            [renderEncoder setFragmentTexture:inMeshTexture atIndex:0];
            [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
            [renderEncoder setVertexBuffer:_meshTextureVertexBuffer offset:0 atIndex:0];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:1 vertexCount:3];
        }
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        
        [commandBuffer commit];
        
        [commandBuffer waitUntilCompleted];
    }
    
    
}


@end
