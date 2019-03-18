//
//  TextureRenderer.h
//  Scanner
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalContext.h"

@interface TextureRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)render: (id<MTLTexture>)inTexture;

@end
