//
//  FuICPPrepareMatrix.h
//  Scanner
//
//  Created by  沈江洋 on 16/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "FusionDefinition.h"

@interface FuICPPrepareMatrix : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (uint)computeCurrentVMap: (id<MTLBuffer>) currentVMap andCurrentNMap: (id<MTLBuffer>) currentNMap
                andPreVMap: (id<MTLBuffer>) preVMap andPreNMap: (id<MTLBuffer>) preNMap
               intoLMatrix: (id<MTLBuffer>) icpLMatrix andRMatrix: (id<MTLBuffer>) icpRMatrix
              withCurrentR: (simd::float3x3) currentF2gRotate andCurrentT: (simd::float3)currentF2gTranslate
                andPreF2gR: (simd::float3x3) preF2gRotate andPreF2gT: (simd::float3)preF2gTranslate
                andPreG2fR: (simd::float3x3) preG2fRotate andPreG2fT: (simd::float3)preG2fTranslate
              andThreshold: (ICPThreshold) icpThreshold
       andIntrinsicXYZ2UVD: (IntrinsicXYZ2UVD) intrinsicXYZ2UVD
                 withLevel: (uint) level;

@end
