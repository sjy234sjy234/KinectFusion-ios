//
//  FuMeshToTexture.h
//  Scanner
//
//  Created by  沈江洋 on 12/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

@interface FuMeshToTexture : NSObject

//it is actually a renderer
- (instancetype)initWithContext: (MetalContext *)context;
- (void)setClearColor:(const MTLClearColor) color;
- (void)drawPoints: (id<MTLBuffer>) extractPointBuffer
           normals: (id<MTLBuffer>) extractNormalBuffer
  intoColorTexture: (id<MTLTexture>) outColorTexture
   andDepthTexture: (id<MTLTexture>) outDepthTexture
     withTransform: (simd::float4x4) mvpTransform;

@end
