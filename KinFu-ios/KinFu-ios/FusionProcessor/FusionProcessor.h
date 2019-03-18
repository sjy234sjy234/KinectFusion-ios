//
//  FusionProcessor.h
//  Scanner
//
//  Created by  沈江洋 on 2018/8/24.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FusionDefinition.h"

@interface FusionProcessor : NSObject

+ (instancetype)shareFusionProcessorWithContext: (MetalContext *)context;

- (instancetype)initWithContext: (MetalContext *)context;

- (void) setupTsdfParameterWithCube: (const simd::float4) cube;

- (BOOL) processDisparityData: (uint8_t *)disparityPixelBuffer withIndex: (int) fusionFrameIndex withTsdfUpdate:(BOOL)isTsdfUpdate;

- (BOOL) processDisparityPixelBuffer: (CVPixelBufferRef)disparityPixelBuffer withIndex: (int) fusionFrameIndex withTsdfUpdate:(BOOL)isTsdfUpdate;

- (id<MTLBuffer>) getExtractPointBuffer;

- (id<MTLBuffer>) getExtractNormalBuffer;

- (id<MTLTexture>) getColorTexture;

- (float) getQuternionY;

- (void)setRenderBackColor:(const simd::float4) color;

@end
