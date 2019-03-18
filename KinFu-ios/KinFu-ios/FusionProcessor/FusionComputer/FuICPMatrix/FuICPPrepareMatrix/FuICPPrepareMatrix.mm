//
//  FuICPPrepareMatrix.m
//  Scanner
//
//  Created by  沈江洋 on 16/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuICPPrepareMatrix.h"

@interface FuICPPrepareMatrix ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> currentF2gRotateBuffer;
@property (nonatomic, strong) id<MTLBuffer> currentF2gTranslateBuffer;
@property (nonatomic, strong) id<MTLBuffer> preF2gRotateBuffer;
@property (nonatomic, strong) id<MTLBuffer> preF2gTranslateBuffer;
@property (nonatomic, strong) id<MTLBuffer> preG2fRotateBuffer;
@property (nonatomic, strong) id<MTLBuffer> preG2fTranslateBuffer;
@property (nonatomic, strong) id<MTLBuffer> icpThresholdBuffer;
@property (nonatomic, strong) id<MTLBuffer> intrinsicXYZ2UVDBuffer;
@property (nonatomic, strong) id<MTLBuffer> occupiedPixelNumberBuffer;

@end

@implementation FuICPPrepareMatrix

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"fuICPPrepareMatrix"];
    
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
    
    
    _currentF2gRotateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3x3)
                                                                      options:MTLResourceOptionCPUCacheModeDefault];
    _currentF2gTranslateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3)
                                                                   options:MTLResourceOptionCPUCacheModeDefault];
    _preF2gRotateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3x3)
                                                               options:MTLResourceOptionCPUCacheModeDefault];
    _preF2gTranslateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3)
                                                               options:MTLResourceOptionCPUCacheModeDefault];
    _preG2fRotateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3x3)
                                                            options:MTLResourceOptionCPUCacheModeDefault];;
    _preG2fTranslateBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float3)
                                                               options:MTLResourceOptionCPUCacheModeDefault];;
    _icpThresholdBuffer = [_metalContext.device newBufferWithLength:sizeof(ICPThreshold)
                                                           options:MTLResourceOptionCPUCacheModeDefault];
    _intrinsicXYZ2UVDBuffer = [_metalContext.device newBufferWithLength:sizeof(IntrinsicXYZ2UVD)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    _occupiedPixelNumberBuffer=[_metalContext.device newBufferWithLength:sizeof(uint) options:MTLResourceOptionCPUCacheModeDefault];
}

- (uint)computeCurrentVMap: (id<MTLBuffer>) currentVMap andCurrentNMap: (id<MTLBuffer>) currentNMap
                andPreVMap: (id<MTLBuffer>) preVMap andPreNMap: (id<MTLBuffer>) preNMap
               intoLMatrix: (id<MTLBuffer>) icpLMatrix andRMatrix: (id<MTLBuffer>) icpRMatrix
              withCurrentR: (simd::float3x3) currentF2gRotate andCurrentT: (simd::float3)currentF2gTranslate
                andPreF2gR: (simd::float3x3) preF2gRotate andPreF2gT: (simd::float3)preF2gTranslate
                andPreG2fR: (simd::float3x3) preG2fRotate andPreG2fT: (simd::float3)preG2fTranslate
              andThreshold: (ICPThreshold) icpThreshold
       andIntrinsicXYZ2UVD: (IntrinsicXYZ2UVD) intrinsicXYZ2UVD
                 withLevel: (uint) level
{
    if(!currentVMap||!currentNMap||!preVMap||!preNMap||!icpLMatrix||!icpRMatrix){
        return 0;
    }
    
    _threadgroupCount.width  = ((PORTRAIT_WIDTH>>level)  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = ((PORTRAIT_HEIGHT>>level) + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
    
    memset(icpLMatrix.contents, 0, icpLMatrix.length);
    memset(icpRMatrix.contents, 0, icpRMatrix.length);
    memcpy([_currentF2gRotateBuffer contents], &currentF2gRotate, sizeof(simd::float3x3));
    memcpy([_currentF2gTranslateBuffer contents], &currentF2gTranslate, sizeof(simd::float3));
    memcpy([_preF2gRotateBuffer contents], &preF2gRotate, sizeof(simd::float3x3));
    memcpy([_preF2gTranslateBuffer contents], &preF2gTranslate, sizeof(simd::float3));
    memcpy([_preG2fRotateBuffer contents], &preG2fRotate, sizeof(simd::float3x3));
    memcpy([_preG2fTranslateBuffer contents], &preG2fTranslate, sizeof(simd::float3));
    memcpy([_icpThresholdBuffer contents], &icpThreshold, sizeof(ICPThreshold));
    memcpy([_intrinsicXYZ2UVDBuffer contents], &intrinsicXYZ2UVD, sizeof(IntrinsicXYZ2UVD));
    
    memset(_occupiedPixelNumberBuffer.contents, 0, _occupiedPixelNumberBuffer.length);
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"ICPPrepareMatrixCommand";
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setBuffer:currentVMap offset:0 atIndex:0];
    [computeEncoder setBuffer:currentNMap offset:0 atIndex:1];
    [computeEncoder setBuffer:preVMap offset:0 atIndex:2];
    [computeEncoder setBuffer:preNMap offset:0 atIndex:3];
    [computeEncoder setBuffer:icpLMatrix offset:0 atIndex:4];
    [computeEncoder setBuffer:icpRMatrix offset:0 atIndex:5];
    [computeEncoder setBuffer:_currentF2gRotateBuffer offset:0 atIndex:6];
    [computeEncoder setBuffer:_currentF2gTranslateBuffer offset:0 atIndex:7];
    [computeEncoder setBuffer:_preF2gRotateBuffer offset:0 atIndex:8];
    [computeEncoder setBuffer:_preF2gTranslateBuffer offset:0 atIndex:9];
    [computeEncoder setBuffer:_preG2fRotateBuffer offset:0 atIndex:10];
    [computeEncoder setBuffer:_preG2fTranslateBuffer offset:0 atIndex:11];
    [computeEncoder setBuffer:_icpThresholdBuffer offset:0 atIndex:12];
    [computeEncoder setBuffer:_intrinsicXYZ2UVDBuffer offset:0 atIndex:13];
    [computeEncoder setBuffer:_occupiedPixelNumberBuffer offset:0 atIndex:14];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    void *baseAddress=_occupiedPixelNumberBuffer.contents;
    uint *uintAddress=(uint*)baseAddress;
    uint occupiedPixelNumber=uintAddress[0];
    return occupiedPixelNumber;
}

@end
