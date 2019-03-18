//
//  DepthToVertexMap.h
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

@interface DepthToVertexMap : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)computeCurrentDepthMap:(const id<MTLBuffer>*)currentDepthMapBufferPyramid intoCurrentVertexMap:(const id<MTLBuffer>*) currentVertexMapBufferPyramid
                andPreDepthMap:(const id<MTLBuffer>*)preDepthMapBufferPyramid intoPreVertexMap:(const id<MTLBuffer>*) preVertexMapBufferPyramid
                   withUVD2XYZ: (const IntrinsicUVD2XYZ*)intrinsicUVD2XYZ;

@end
