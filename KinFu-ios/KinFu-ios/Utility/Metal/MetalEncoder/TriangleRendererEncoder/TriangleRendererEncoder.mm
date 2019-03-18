//
//  TriangleRendererEncoder.m
//  Scanner
//
//  Created by  沈江洋 on 2018/9/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "TriangleRendererEncoder.h"

@interface TriangleRendererEncoder ()
{
    MTLClearColor m_clearColor;
    double m_clearDepth;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipeline;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;
@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation TriangleRendererEncoder

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
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"triangle_vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"triangle_fragment_main"];
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    _renderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                               error:&error];
    if (!_renderPipeline)
    {
        NSLog(@"Error occurred when creating triangle render pipeline state: %@", error);
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

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer
              dstColorTexture: (id<MTLTexture>) colorTexture
              dstDepthTexture: (id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (id<MTLBuffer>) pointBuffer
                  normalBuffer: (id<MTLBuffer>) normalBuffer
                    mvpMatrix: (simd::float4x4)mvpTransform
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
    
    if(!pointBuffer || !normalBuffer || pointBuffer.length != normalBuffer.length)
    {
        NSLog(@"invalid point/normal buffer");
        return ;
    }
    
    int tNum = pointBuffer.length / (3 * sizeof(float));
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    {
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
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor: passDescriptor];
        
        [commandEncoder setRenderPipelineState: _renderPipeline];
        [commandEncoder setDepthStencilState: _depthState];
        [commandEncoder setFrontFacingWinding: MTLWindingCounterClockwise];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder setVertexBuffer: pointBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer: normalBuffer offset:0 atIndex:1];
        [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex:2];
        [commandEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart: 0 vertexCount: tNum];
        
        [commandEncoder endEncoding];
    }
    
}

@end
