//
//  FuTextureToDepth.h
//  Scanner
//
//  Created by  沈江洋 on 13/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FusionDefinition.h"

@interface FuTextureToDepth : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute:(id<MTLTexture>) inDepthTexture intoTexture: (id<MTLBuffer>)outDepthMapBuffer with: (CameraNDC2Depth) cameraFrustum;

@end
