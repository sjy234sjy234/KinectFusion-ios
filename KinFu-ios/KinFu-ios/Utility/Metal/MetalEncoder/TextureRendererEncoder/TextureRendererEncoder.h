//
//  TextureRendererEncoder.h
//  Learn-Metal
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

@interface TextureRendererEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)setQuadVertex: (const float *)quadVertex;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer sourceTexture: (id<MTLTexture>) inTexture destinationTexture: (id<MTLTexture>) outTexture;

@end
