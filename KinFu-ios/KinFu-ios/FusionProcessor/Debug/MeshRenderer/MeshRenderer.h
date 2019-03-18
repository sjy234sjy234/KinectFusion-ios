//
//  MeshRenderer.h
//  Scanner
//
//  Created by  沈江洋 on 23/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

@interface MeshRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)draw: (id<MTLBuffer>) extractPointBuffer withTransform: (simd::float4x4) mvpTransform;

@end
