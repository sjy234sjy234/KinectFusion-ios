//
//  PointRendererEncoder.m
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/8.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "PointRendererEncoder.h"


@interface PointRendererEncoder ()
{
    MTLClearColor m_clearColor;
    double m_clearDepth;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> pointRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> pointSizeBuffer;
@property (nonatomic, strong) id<MTLBuffer> pointColorBuffer;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;
@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation PointRendererEncoder

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
    
    id<MTLFunction> pointVertexFunc = [library newFunctionWithName:@"pointRenderer_vertex_main"];
    id<MTLFunction> pointFragmentFunc = [library newFunctionWithName:@"pointRenderer_fragment_main"];
    
    MTLRenderPipelineDescriptor *pointPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pointPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pointPipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    pointPipelineDescriptor.vertexFunction = pointVertexFunc;
    pointPipelineDescriptor.fragmentFunction = pointFragmentFunc;
    
    _pointRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pointPipelineDescriptor
                                                                                error:&error];
    
    if (!_pointRenderPipeline)
    {
        NSLog(@"Error occurred when creating point render pipeline state: %@", error);
    }
    
    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthWriteEnabled = YES;
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    _depthState = [_metalContext.device newDepthStencilStateWithDescriptor:depthDescriptor];
}

- (void)buildResources
{
    m_clearColor = {1.0, 1.0, 1.0, 1.0};
    m_clearDepth = 1.0;
    
    const float size = 15;
    _pointSizeBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_pointSizeBuffer contents], &size, sizeof(float));
    
    const simd::float4 color = {0.0, 1.0, 0.0, 1.0};
    _pointColorBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_pointColorBuffer contents], &color, sizeof(simd::float4));
    
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)setClearColor:(const MTLClearColor) color
{
    m_clearColor = color;
}

- (void)setClearDepth:(const double) depth
{
    m_clearDepth = depth;
}

- (void)setPointSize: (const float) size
{
    memcpy([_pointSizeBuffer contents], &size, sizeof(float));
}

- (void)setPointColor: (const simd::float4) color
{
    memcpy([_pointColorBuffer contents], &color, sizeof(simd::float4));
}

- (void)encodeToCommandBuffer: (const id<MTLCommandBuffer>) commandBuffer
                     outColor: (const id<MTLTexture>) colorTexture
                     outDepth: (const id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (const id<MTLBuffer>) pointBuffer
                    mvpMatrix: (const simd::float4x4)mvpTransform
{
    if(!commandBuffer)
    {
        NSLog(@"invalid command buffer");
        return ;
    }
    if(!colorTexture || !depthTexture)
    {
        NSLog(@"invalid texture");
        return ;
    }
    if(!pointBuffer)
    {
        NSLog(@"invalid points");
        return;
    }
    
    int pNum = pointBuffer.length / (3 * sizeof(float));
    
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = colorTexture;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    if(isClearColor)
    {
        passDescriptor.colorAttachments[0].clearColor = m_clearColor;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    }
    else
    {
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    passDescriptor.depthAttachment.texture = depthTexture;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    if(isClearDepth)
    {
        passDescriptor.depthAttachment.clearDepth = m_clearDepth;
        passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    }
    else
    {
        passDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
    }
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [commandEncoder setRenderPipelineState: _pointRenderPipeline];
    [commandEncoder setDepthStencilState: _depthState];
    [commandEncoder setVertexBuffer: pointBuffer offset:0 atIndex: 0];
    [commandEncoder setVertexBuffer: _pointSizeBuffer offset:0 atIndex: 1];
    [commandEncoder setVertexBuffer: _pointColorBuffer offset:0 atIndex: 2];
    [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex: 3];
    [commandEncoder drawPrimitives: MTLPrimitiveTypePoint vertexStart: 0 vertexCount: pNum];
    [commandEncoder endEncoding];
}

@end
