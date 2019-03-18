//
//  FuTsdfFusioner.h
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

@interface FuTsdfFusioner : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute:(id<MTLBuffer>)inDepthMapBuffer intoTsdfVertexBuffer:(id<MTLBuffer>) outTsdfVertexBuffer withIntrinsicXYZ2UVD: (IntrinsicXYZ2UVD)intrinsicXYZ2UVD andTsdfParameter: (TsdfParameter) tsdfParameter andTransform: (simd::float4x4) globalToFrameTransform;

@end
