//
//  FuDepthToVertex.h
//  Scanner
//
//  Created by  沈江洋 on 04/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FusionDefinition.h"

@interface FuDepthToVertex : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute:(id<MTLBuffer>)inDepthMapBuffer intoVertexMapBuffer:(id<MTLBuffer>) outVertexMapBuffer withLevel:(uint) level andIntrinsicUVD2XYZ: (IntrinsicUVD2XYZ)m_intrinsicUVD2XYZ;

@end
