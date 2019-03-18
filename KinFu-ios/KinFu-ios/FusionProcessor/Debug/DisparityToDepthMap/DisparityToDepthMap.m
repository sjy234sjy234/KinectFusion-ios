//
//  DisparityToDepthMap.m
//  Scanner
//
//  Created by  沈江洋 on 18/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "DisparityToDepthMap.h"

@interface DisparityToDepthMap ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@end

@implementation DisparityToDepthMap

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"disparityToDepthMap"];
    
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
    
    _threadgroupSize = MTLSizeMake(THREADGROUP_WIDTH, THREADGROUP_HEIGHT, 1);
    _threadgroupCount.width  = (PORTRAIT_WIDTH  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (PORTRAIT_HEIGHT + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
}

- (id<MTLBuffer>)bufferWithF16PixelBuffer:(CVPixelBufferRef)f16PixelBuffer
{
    id<MTLBuffer> buffer;
    
    size_t width = CVPixelBufferGetWidth(f16PixelBuffer);
    size_t height = CVPixelBufferGetHeight(f16PixelBuffer);
    
    CVPixelBufferLockBaseAddress(f16PixelBuffer,  0);
    
    void *baseAddress=CVPixelBufferGetBaseAddress(f16PixelBuffer);
    float16_t *float16Address = (float16_t *)(baseAddress);
    
    buffer = [_metalContext.device newBufferWithBytes:float16Address
                                               length:PORTRAIT_WIDTH*PORTRAIT_HEIGHT*2
                                              options:MTLResourceOptionCPUCacheModeDefault];
    
    CVPixelBufferUnlockBaseAddress(f16PixelBuffer, 0);
    
    return buffer;
}

- (void)compute:(const CVPixelBufferRef)disparityPixelBuffer intoDepthMapBuffer:(const id<MTLBuffer> *) depthMapBufferPyramid
{
    if(!disparityPixelBuffer||!depthMapBufferPyramid){
        return;
    }
    
    id<MTLBuffer> inDisparityMapBuffer = [self bufferWithF16PixelBuffer:disparityPixelBuffer];
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"DisparityToDepthMapCommand";
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_computePipeline];
    
    [computeEncoder setBuffer:inDisparityMapBuffer offset:0 atIndex:0];
    
    [computeEncoder setBuffer:depthMapBufferPyramid[0] offset:0 atIndex:1];
    
    [computeEncoder setBuffer:depthMapBufferPyramid[1] offset:0 atIndex:2];
    
    [computeEncoder setBuffer:depthMapBufferPyramid[2] offset:0 atIndex:3];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    
    [computeEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
}

@end
