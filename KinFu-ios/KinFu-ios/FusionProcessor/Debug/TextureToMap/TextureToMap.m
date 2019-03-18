//
//  DepthTextureToMap.m
//  Scanner
//
//  Created by  沈江洋 on 13/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "TextureToMap.h"

@interface TextureToMap ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@property (nonatomic, strong) id<MTLBuffer> cameraFrustumBuffer;

@end

@implementation TextureToMap

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
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"textureToMap"];
    
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
    
    _threadgroupCount.width  = (PORTRAIT_WIDTH  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (PORTRAIT_HEIGHT + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = 1;
    
    _cameraFrustumBuffer = [_metalContext.device newBufferWithLength:sizeof(CameraNDC2Depth)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)compute:(id<MTLTexture>) inDepthTexture intoTexture: (id<MTLBuffer>)outDepthMapBuffer with: (CameraNDC2Depth) cameraFrustum
{
    if(!inDepthTexture||!outDepthMapBuffer){
        return;
    }
    
    memcpy([_cameraFrustumBuffer contents], &cameraFrustum, sizeof(CameraNDC2Depth));
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"TextureToMapCommand";
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    [computeEncoder setComputePipelineState:_computePipeline];
    
    [computeEncoder setTexture:inDepthTexture atIndex:0];
    
    [computeEncoder setBuffer:outDepthMapBuffer offset:0 atIndex:0];
    
    [computeEncoder setBuffer:_cameraFrustumBuffer offset:0 atIndex:1];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    
    [computeEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
    
//        void *baseAddress=outDepthMapBuffer.contents;
//        float *floatAddress=(float*)baseAddress;
//    NSLog(@"first 10 out: %f, %f, %f, %f, %f, %f, %f, %f, %f, %f", floatAddress[0], floatAddress[1], floatAddress[2], floatAddress[3], floatAddress[4], floatAddress[5], floatAddress[6], floatAddress[7], floatAddress[8], floatAddress[320*480+240]);

}

@end
