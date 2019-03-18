//
//  MatrixMultiplication.h
//  Scanner
//
//  Created by  沈江洋 on 15/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "definition.h"

@interface MatrixMultiplication : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)computeWithM: (uint) M andN: (uint)N andK: (uint)K;

@end
