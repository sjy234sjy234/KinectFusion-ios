//
//  MeshRenderer.m
//  Scanner
//
//  Created by  沈江洋 on 23/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "MeshRenderer.h"
#import "MathUtilities.hpp"

@interface MeshRenderer()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipeline;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;

@end

@implementation MeshRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        [self buildPipelines];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"meshRenderer_vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"meshRenderer_fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    
    _renderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                           error:&error];
    
    if (!_renderPipeline)
    {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }
    
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)draw: (id<MTLBuffer>) extractPointBuffer withTransform: (simd::float4x4) mvpTransform;
{
    if(!extractPointBuffer)
    {
        return;
    }
    
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    if (drawable)
    {
        memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(simd::float4x4));
        
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"MeshRendererCommand";
        
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.8, 0.8, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        [renderEncoder setRenderPipelineState:_renderPipeline];
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setVertexBuffer:extractPointBuffer offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:_mvpTransformBuffer offset:0 atIndex:1];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:extractPointBuffer.length/32];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        
        [commandBuffer commit];
        
        [commandBuffer waitUntilCompleted];
    }
}

@end
