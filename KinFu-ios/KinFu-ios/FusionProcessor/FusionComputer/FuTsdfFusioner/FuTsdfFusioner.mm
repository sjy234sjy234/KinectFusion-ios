//
//  FuTsdfFusioner.m
//  Scanner
//
//  Created by  沈江洋 on 2018/8/24.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuTsdfFusioner.h"

@interface FuTsdfFusioner ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> depthMapSizeBuffer;
@property (nonatomic, strong) id<MTLBuffer> intrinsicXYZ2UVDBuffer;
@property (nonatomic, strong) id<MTLBuffer> tsdfParameterBuffer;
@property (nonatomic, strong) id<MTLBuffer> globalToFrameTransformBuffer;

@end

@implementation FuTsdfFusioner

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"fuTsdfFusioner"];
    
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
    _threadgroupCount.width  = (TSDF_RESOLUTION  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (TSDF_RESOLUTION + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = TSDF_RESOLUTION;
    
    _depthMapSizeBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::int2)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    simd::int2 depthMapSize={PORTRAIT_WIDTH,PORTRAIT_HEIGHT};
    memcpy([_depthMapSizeBuffer contents], &depthMapSize, sizeof(simd::int2));
    
    _intrinsicXYZ2UVDBuffer = [_metalContext.device newBufferWithLength:sizeof(IntrinsicXYZ2UVD)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    _tsdfParameterBuffer = [_metalContext.device newBufferWithLength:sizeof(TsdfParameter)
                                                             options:MTLResourceOptionCPUCacheModeDefault];
    _globalToFrameTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                                      options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)compute:(id<MTLBuffer>)inDepthMapBuffer intoTsdfVertexBuffer:(id<MTLBuffer>) outTsdfVertexBuffer withIntrinsicXYZ2UVD: (IntrinsicXYZ2UVD)intrinsicXYZ2UVD andTsdfParameter: (TsdfParameter) tsdfParameter andTransform: (simd::float4x4) globalToFrameTransform
{
    if(!inDepthMapBuffer||!outTsdfVertexBuffer){
        return;
    }
    
    memcpy([_globalToFrameTransformBuffer contents], &globalToFrameTransform, sizeof(simd::float4x4));
    memcpy([_intrinsicXYZ2UVDBuffer contents], &intrinsicXYZ2UVD, sizeof(IntrinsicXYZ2UVD));
    memcpy([_tsdfParameterBuffer contents], &tsdfParameter, sizeof(TsdfParameter));
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FuTsdfFusionerCommand";
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setBuffer:inDepthMapBuffer offset:0 atIndex:0];
    [computeEncoder setBuffer:outTsdfVertexBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_depthMapSizeBuffer offset:0 atIndex:2];
    [computeEncoder setBuffer:_intrinsicXYZ2UVDBuffer offset:0 atIndex:3];
    [computeEncoder setBuffer:_tsdfParameterBuffer offset:0 atIndex:4];
    [computeEncoder setBuffer:_globalToFrameTransformBuffer offset:0 atIndex:5];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
    [commandBuffer commit];
//    [commandBuffer waitUntilCompleted];
}

@end

