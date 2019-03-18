//
//  FuMCubeExtract.m
//  Scanner
//
//  Created by  沈江洋 on 10/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuMCubeExtract.h"

@interface FuMCubeExtract ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> mCubeTriangleTableBuffer;
@property (nonatomic, strong) id<MTLBuffer> activeVoxelNumberBuffer;
@property (nonatomic, strong) id<MTLBuffer> tsdfParameterBuffer;
@property (nonatomic, strong) id<MTLBuffer> mCubeParameterBuffer;

@end

@implementation FuMCubeExtract

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"fuMCubeExtract"];
    
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
    
    _threadgroupSize = MTLSizeMake(THREADGROUP_SIZE, 1, 1);
    
    _mCubeTriangleTableBuffer=[_metalContext.device newBufferWithLength:sizeof(MCubeTriangleTable) options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_mCubeTriangleTableBuffer contents], &MCubeTriangleTable, sizeof(MCubeTriangleTable));
    _activeVoxelNumberBuffer=[_metalContext.device newBufferWithLength:sizeof(uint) options:MTLResourceOptionCPUCacheModeDefault];
    _tsdfParameterBuffer = [_metalContext.device newBufferWithLength:sizeof(TsdfParameter)
                                                             options:MTLResourceOptionCPUCacheModeDefault];
    _mCubeParameterBuffer = [_metalContext.device newBufferWithLength:sizeof(MCubeParameter)
                                                              options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)compute:(id<MTLBuffer>)inActiveVoxelInfoBuffer andTsdfVertexBuffer:(id<MTLBuffer>)inTsdfVertexBuffer withActiveVoxelNumber:(uint) activeVoxelNumber andTsdfParameter: (TsdfParameter) tsdfParameter andMCubeParameter:(MCubeParameter)mCubeParameter andOutMCubeExtractPointBufferT: (id<MTLBuffer>) outMCubeExtractPointBuffer andOutMCubeExtractNormalBuffer: (id<MTLBuffer>) outMCubeExtractNormalBuffer
{
    if(!inActiveVoxelInfoBuffer || !outMCubeExtractPointBuffer || !outMCubeExtractNormalBuffer){
        return;
    }
    
    _threadgroupCount.width  =ceil((float)activeVoxelNumber / _threadgroupSize.width);
    _threadgroupCount.height = 1;
    _threadgroupCount.depth = 1;
    memcpy([_activeVoxelNumberBuffer contents], &activeVoxelNumber, sizeof(uint));
    memcpy([_tsdfParameterBuffer contents], &tsdfParameter, sizeof(TsdfParameter));
    memcpy([_mCubeParameterBuffer contents], &mCubeParameter, sizeof(MCubeParameter));

    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FuMCubeExtractCommand";
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setBuffer:inActiveVoxelInfoBuffer offset:0 atIndex:0];
    [computeEncoder setBuffer:inTsdfVertexBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_mCubeTriangleTableBuffer offset:0 atIndex:2];
    [computeEncoder setBuffer:_activeVoxelNumberBuffer offset:0 atIndex:3];
    [computeEncoder setBuffer:_tsdfParameterBuffer offset:0 atIndex:4];
    [computeEncoder setBuffer:_mCubeParameterBuffer offset:0 atIndex:5];
    [computeEncoder setBuffer: outMCubeExtractPointBuffer offset:0 atIndex:6];
    [computeEncoder setBuffer: outMCubeExtractNormalBuffer offset:0 atIndex:7];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
    [commandBuffer commit];
//    [commandBuffer waitUntilCompleted];
}

@end
