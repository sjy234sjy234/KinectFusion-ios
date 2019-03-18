//
//  FuMCubeTraverse.m
//  Scanner
//
//  Created by  沈江洋 on 10/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuMCubeTraverse.h"

@interface FuMCubeTraverse ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> mCubeNumVertsTableBuffer;
@property (nonatomic, strong) id<MTLBuffer> mCubeParameterBuffer;
@property (nonatomic, strong) id<MTLBuffer> activeVoxelNumberBuffer;

@end

@implementation FuMCubeTraverse

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"fuMCubeTraverse"];
    
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
    
    _mCubeNumVertsTableBuffer=[_metalContext.device newBufferWithLength:sizeof(MCubeNumVertsTable) options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_mCubeNumVertsTableBuffer contents], &MCubeNumVertsTable, sizeof(MCubeNumVertsTable));
    
    _mCubeParameterBuffer = [_metalContext.device newBufferWithLength:sizeof(MCubeParameter)
                                                             options:MTLResourceOptionCPUCacheModeDefault];
    
    _activeVoxelNumberBuffer=[_metalContext.device newBufferWithLength:sizeof(uint) options:MTLResourceOptionCPUCacheModeDefault];
}

- (uint)compute:(id<MTLBuffer>)inTsdfVertexBuffer intoActiveVoxelInfo:(id<MTLBuffer>) outActiveVoxelInfoBuffer withMCubeParameter:(MCubeParameter)mCubeParameter
{
    if(!inTsdfVertexBuffer||!outActiveVoxelInfoBuffer){
        return UINT_MAX;
    }
    
    memcpy([_mCubeParameterBuffer contents], &mCubeParameter, sizeof(MCubeParameter));
    memset(_activeVoxelNumberBuffer.contents, 0, _activeVoxelNumberBuffer.length);
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FuMCubeTraverseCommand";
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setBuffer:inTsdfVertexBuffer offset:0 atIndex:0];
    [computeEncoder setBuffer:outActiveVoxelInfoBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_mCubeNumVertsTableBuffer offset:0 atIndex:2];
    [computeEncoder setBuffer:_mCubeParameterBuffer offset:0 atIndex:3];
    [computeEncoder setBuffer:_activeVoxelNumberBuffer offset:0 atIndex:4];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    void *baseAddress=_activeVoxelNumberBuffer.contents;
    uint *uintAddress=(uint*)baseAddress;
    uint activeVoxelNumber=uintAddress[0];
    return activeVoxelNumber;
}

@end
