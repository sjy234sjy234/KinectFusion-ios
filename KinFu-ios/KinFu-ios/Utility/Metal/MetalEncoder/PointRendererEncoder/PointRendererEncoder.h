//
//  PointRendererEncoder.h
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/8.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

@interface PointRendererEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)setClearColor:(const MTLClearColor) color;
- (void)setClearDepth:(const double) depth;
- (void)setPointSize: (const float) size;
- (void)setPointColor: (const simd::float4) color;
- (void)encodeToCommandBuffer: (const id<MTLCommandBuffer>) commandBuffer
                     outColor: (const id<MTLTexture>) colorTexture
                     outDepth: (const id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (const id<MTLBuffer>) pointBuffer
                    mvpMatrix: (const simd::float4x4)mvpTransform;

@end
