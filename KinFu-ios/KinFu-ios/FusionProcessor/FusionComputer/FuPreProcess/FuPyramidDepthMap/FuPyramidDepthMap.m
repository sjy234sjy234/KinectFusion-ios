//
//  FuPyramidDepthMap.m
//  Scanner
//
//  Created by  沈江洋 on 04/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuPyramidDepthMap.h"

@interface FuPyramidDepthMap ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@end

@implementation FuPyramidDepthMap

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"fuPyramidDepthMap"];
    
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
}

- (void)compute:(id<MTLBuffer>)inDepthMapBuffer intoDepthMapBuffer:(id<MTLBuffer>) outDepthMapBuffer withLevel:(uint) level
{
    if(!inDepthMapBuffer||!outDepthMapBuffer){
        return;
    }
    
    _threadgroupCount.width  = ((PORTRAIT_WIDTH>>level)  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = ((PORTRAIT_HEIGHT>>level) + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FuPyramidDepthMapCommand";
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_computePipeline];
    
    [computeEncoder setBuffer:inDepthMapBuffer offset:0 atIndex:0];
    
    [computeEncoder setBuffer:outDepthMapBuffer offset:0 atIndex:1];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    
    [computeEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
    
}

@end
