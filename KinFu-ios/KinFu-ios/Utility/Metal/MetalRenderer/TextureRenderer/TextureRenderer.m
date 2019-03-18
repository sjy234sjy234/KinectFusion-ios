//
//  TextureRenderer.m
//  Scanner
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import "TextureRenderer.h"
#import "TextureRendererEncoder.h"

@interface TextureRenderer ()

@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@end

@implementation TextureRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.textureRendererEncoder = [[TextureRendererEncoder alloc] initWithContext: _metalContext];
    }
    return self;
}

- (void)render: (id<MTLTexture>)inTexture
{
    if(!inTexture)
    {
        NSLog(@"invalid texture");
        return;
    }
    
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {   
        //new commander buffer
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"TextureRendererCommand";
        
        //encode drawable render process
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: inTexture destinationTexture: drawable.texture];
        [commandBuffer presentDrawable:drawable];
        
        //commit commander buffer
        [commandBuffer commit];
    }
}

@end
