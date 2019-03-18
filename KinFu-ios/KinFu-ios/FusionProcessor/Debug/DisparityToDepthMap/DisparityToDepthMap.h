//
//  DisparityToDepthMap.h
//  Scanner
//
//  Created by  沈江洋 on 18/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FushionDefinition.h"

@interface DisparityToDepthMap : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute:(const CVPixelBufferRef)disparityPixelBuffer intoDepthMapBuffer:(const id<MTLBuffer> *) depthMapBufferPyramid;

@end
