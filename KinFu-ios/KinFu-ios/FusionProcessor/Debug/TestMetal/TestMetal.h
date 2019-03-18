//
//  TestMetal.h
//  Scanner
//
//  Created by  沈江洋 on 09/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"
#import "definition.h"

@interface TestMetal : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)compute;

@end
