//
//  TestMetal.m
//  Scanner
//
//  Created by  沈江洋 on 09/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "TestMetal.h"

@interface TestMetal ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@end

@implementation TestMetal
{
    id<MTLBuffer> m_inBuffer;
    id<MTLBuffer> m_outBuffer;
    id<MTLBuffer> m_testData;
}

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

- (void)buildResources
{
    m_inBuffer=[_metalContext.device newBufferWithLength:TSDF_RESOLUTION*TSDF_RESOLUTION*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    m_outBuffer=[_metalContext.device newBufferWithLength:TSDF_RESOLUTION*TSDF_RESOLUTION*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    m_testData=[_metalContext.device newBufferWithLength:sizeof(uint) options:MTLResourceOptionCPUCacheModeDefault];
    
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    // Load the kernel function from the library
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"testMetal"];
    
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
    _threadgroupCount.width  = ((TSDF_RESOLUTION)  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = ((TSDF_RESOLUTION) + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
}

-(void) resetData
{
    memset(m_inBuffer.contents, 0, m_inBuffer.length);
    memset(m_outBuffer.contents, 0, m_outBuffer.length);
    memset(m_testData.contents, 0, m_testData.length);
}

- (void)compute
{
    [self resetData];
    
//    void *baseAddress=m_testData.contents;
//    uint *testDataAddress=(uint*)baseAddress;
//    NSLog(@"before:");
//    NSLog(@"test data: %d", testDataAddress[0]);
    
//    void *inBaseAddress=m_inBuffer.contents;
//    float *inFloatAddress=(float*)inBaseAddress;
//    NSLog(@"before:");
//    NSLog(@"in buffer 127*128+127: %f", inFloatAddress[127*128+127]);
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"TestMetalCommand";
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_computePipeline];
    
    [computeEncoder setBuffer:m_inBuffer offset:0 atIndex:0];
    
    [computeEncoder setBuffer:m_outBuffer offset:0 atIndex:1];
    
    [computeEncoder setBuffer:m_testData offset:0 atIndex:2];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    
    [computeEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
    
//    NSLog(@"after:");
//    NSLog(@"test data: %d", testDataAddress[0]);
    
//    NSLog(@"after:");
//    NSLog(@"in buffer 127*128+127: %f", inFloatAddress[127*128+127]);
}

@end
