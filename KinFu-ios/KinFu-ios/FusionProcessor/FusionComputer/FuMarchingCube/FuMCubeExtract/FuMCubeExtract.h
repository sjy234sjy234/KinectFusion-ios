//
//  FuMCubeExtract.h
//  Scanner
//
//  Created by  沈江洋 on 10/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FusionDefinition.h"

@interface FuMCubeExtract : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute:(id<MTLBuffer>)inActiveVoxelInfoBuffer andTsdfVertexBuffer:(id<MTLBuffer>)inTsdfVertexBuffer withActiveVoxelNumber:(uint) activeVoxelNumber andTsdfParameter: (TsdfParameter) tsdfParameter andMCubeParameter:(MCubeParameter)mCubeParameter andOutMCubeExtractPointBufferT: (id<MTLBuffer>) outMCubeExtractPointBuffer andOutMCubeExtractNormalBuffer: (id<MTLBuffer>) outMCubeExtractNormalBuffer;

@end
