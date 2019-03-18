//
//  ICPReduceMatrix.h
//  Scanner
//
//  Created by  沈江洋 on 16/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#import "MetalContext.h"
#import "definition.h"

@interface ICPReduce : NSObject

- (instancetype)initWithContext: (MetalContext *)context;

- (void)computeLeftMatrix:(id<MTLBuffer>)leftMatrixBuffer andRightmatrix: (id<MTLBuffer>)rightMatrixBuffer intoLeftReduce: (id<MTLBuffer>)leftReduceBuffer andRightReduce:(id<MTLBuffer>)rightReduceBuffer withLevel: (uint) level andOccupiedNumber: (uint)occupiedPixelNumber;

@end
