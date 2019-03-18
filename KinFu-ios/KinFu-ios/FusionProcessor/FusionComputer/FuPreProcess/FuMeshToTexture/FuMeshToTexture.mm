//
//  FuMeshToTexture.m
//  Scanner
//
//  Created by  沈江洋 on 12/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuMeshToTexture.h"
#import "FusionDefinition.h"
#import "MathUtilities.hpp"

@interface FuMeshToTexture ()
{
    MTLClearColor m_clearColor;
}

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipeline;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;

@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation FuMeshToTexture

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
        m_clearColor = {1.0, 1.0, 1.0, 1.0};
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"fuMeshToTexture_vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fuMeshToTexture_fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    
    _renderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                                error:&error];
    
    if (!_renderPipeline)
    {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }
    
    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthWriteEnabled = YES;
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    _depthState = [_metalContext.device newDepthStencilStateWithDescriptor:depthDescriptor];
    
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)setClearColor:(const MTLClearColor) color
{
    m_clearColor = color;
}

- (void)drawPoints: (id<MTLBuffer>) extractPointBuffer
           normals: (id<MTLBuffer>) extractNormalBuffer
  intoColorTexture: (id<MTLTexture>) outColorTexture
   andDepthTexture: (id<MTLTexture>) outDepthTexture
     withTransform: (simd::float4x4) mvpTransform
{
    if(!extractPointBuffer || !extractNormalBuffer || !outColorTexture || !outDepthTexture)
    {
        return;
    }
    
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(simd::float4x4));
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FuMeshToTextureCommand";
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = outColorTexture;
    passDescriptor.colorAttachments[0].clearColor = m_clearColor;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    passDescriptor.depthAttachment.texture = outDepthTexture;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    [renderEncoder setRenderPipelineState:_renderPipeline];
    [renderEncoder setDepthStencilState:_depthState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setVertexBuffer:extractPointBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:extractNormalBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:_mvpTransformBuffer offset:0 atIndex:2];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:extractPointBuffer.length/12];
    
    [renderEncoder endEncoding];
    
    [commandBuffer commit];
    
}

@end
