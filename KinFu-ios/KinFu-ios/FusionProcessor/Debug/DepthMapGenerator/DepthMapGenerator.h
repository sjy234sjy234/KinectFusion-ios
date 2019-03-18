//
//  DepthMapGenerator.h
//  Scanner
//
//  Created by  沈江洋 on 11/03/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FushionDefinition.h"

@interface DepthMapGenerator : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void) computeDisparity:(const CVPixelBufferRef)currentDisparityPixelBuffer intoCurrentDepthMapBuffer:(const id<MTLBuffer> *) currentDepthMapBufferPyramid
               andTexture:(const id<MTLTexture>) preDepthTexture intoPreDepthMap: (const id<MTLBuffer> *)preDepthMapBufferPyramid with: (const CameraNDC2Depth) cameraNDC2Depth;

@end
