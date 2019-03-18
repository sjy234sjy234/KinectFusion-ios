//
//  DepthToVertexMap.m
//  Scanner
//
//  Created by  沈江洋 on 18/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "DepthToVertexMap.h"

@interface DepthToVertexMap ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> intrinsicUVD2XYZBuffer0;
@property (nonatomic, strong) id<MTLBuffer> intrinsicUVD2XYZBuffer1;
@property (nonatomic, strong) id<MTLBuffer> intrinsicUVD2XYZBuffer2;

@end

@implementation DepthToVertexMap

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    // Load the kernel function from the library
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"depthToVertexMap"];
    
    // Create a compute pipeline state
    _computePipeline = [_metalContext.device newComputePipelineStateWithFunction:kernelFunction
                                                                           error:&error];
    
    if(!_computePipeline)
    {
        // Compute pipeline State creation could fail if kernelFunction failed to load from the
        //   library.  If the Metal API validation is enabled, we automatically be given more
        //   information about what went wrong.  (Metal API validation is enabled by default
        //   when a debug build is run from Xcode)
        NSLog(@"Failed to create compute pipeline state, error %@", error);
    }
    
    _threadgroupSize = MTLSizeMake((THREADGROUP_WIDTH), (THREADGROUP_HEIGHT), 1);
    _threadgroupCount.width  = ((PORTRAIT_WIDTH)  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = ((PORTRAIT_HEIGHT) + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
    
    _intrinsicUVD2XYZBuffer0 = [_metalContext.device newBufferWithLength:sizeof(IntrinsicUVD2XYZ)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    _intrinsicUVD2XYZBuffer1 = [_metalContext.device newBufferWithLength:sizeof(IntrinsicUVD2XYZ)
                                                                 options:MTLResourceOptionCPUCacheModeDefault];
    _intrinsicUVD2XYZBuffer2 = [_metalContext.device newBufferWithLength:sizeof(IntrinsicUVD2XYZ)
                                                                 options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)computeCurrentDepthMap:(const id<MTLBuffer>*)currentDepthMapBufferPyramid intoCurrentVertexMap:(const id<MTLBuffer>*) currentVertexMapBufferPyramid
                andPreDepthMap:(const id<MTLBuffer>*)preDepthMapBufferPyramid intoPreVertexMap:(const id<MTLBuffer>*) preVertexMapBufferPyramid
                   withUVD2XYZ: (const IntrinsicUVD2XYZ*)intrinsicUVD2XYZ
{
    if(!currentDepthMapBufferPyramid||!currentVertexMapBufferPyramid||!preDepthMapBufferPyramid||!preVertexMapBufferPyramid){
        return;
    }
    
    memcpy([_intrinsicUVD2XYZBuffer0 contents], &intrinsicUVD2XYZ[0], sizeof(IntrinsicUVD2XYZ));
    memcpy([_intrinsicUVD2XYZBuffer1 contents], &intrinsicUVD2XYZ[1], sizeof(IntrinsicUVD2XYZ));
    memcpy([_intrinsicUVD2XYZBuffer2 contents], &intrinsicUVD2XYZ[2], sizeof(IntrinsicUVD2XYZ));
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"DepthToVertexMapCommand";
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_computePipeline];
    
    [computeEncoder setBuffer:currentDepthMapBufferPyramid[0] offset:0 atIndex:0];
    
    [computeEncoder setBuffer:currentDepthMapBufferPyramid[1] offset:0 atIndex:1];
    
    [computeEncoder setBuffer:currentDepthMapBufferPyramid[2] offset:0 atIndex:2];
    
    [computeEncoder setBuffer:currentVertexMapBufferPyramid[0] offset:0 atIndex:3];
    
    [computeEncoder setBuffer:currentVertexMapBufferPyramid[1] offset:0 atIndex:4];
    
    [computeEncoder setBuffer:currentVertexMapBufferPyramid[2] offset:0 atIndex:5];
    
    [computeEncoder setBuffer:preDepthMapBufferPyramid[0] offset:0 atIndex:6];
    
    [computeEncoder setBuffer:preDepthMapBufferPyramid[1] offset:0 atIndex:7];
    
    [computeEncoder setBuffer:preDepthMapBufferPyramid[2] offset:0 atIndex:8];
    
    [computeEncoder setBuffer:preVertexMapBufferPyramid[0] offset:0 atIndex:9];
    
    [computeEncoder setBuffer:preVertexMapBufferPyramid[1] offset:0 atIndex:10];
    
    [computeEncoder setBuffer:preVertexMapBufferPyramid[2] offset:0 atIndex:11];
    
    [computeEncoder setBuffer:_intrinsicUVD2XYZBuffer0 offset:0 atIndex:12];
    
    [computeEncoder setBuffer:_intrinsicUVD2XYZBuffer1 offset:0 atIndex:13];
    
    [computeEncoder setBuffer:_intrinsicUVD2XYZBuffer2 offset:0 atIndex:14];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    
    [computeEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
}

@end
