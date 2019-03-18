//
//  TriangleRendererEncoder.h
//  Scanner
//
//  Created by  沈江洋 on 2018/9/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

@interface TriangleRendererEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)setClearColor:(const MTLClearColor) color;
- (void)setClearDepth:(const double) depth;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer
              dstColorTexture: (id<MTLTexture>) colorTexture
              dstDepthTexture: (id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (id<MTLBuffer>) pointBuffer
                 normalBuffer: (id<MTLBuffer>) normalBuffer
                    mvpMatrix: (simd::float4x4)mvpTransform;

@end
