#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>

@protocol MTLDevice, MTLLibrary, MTLCommandQueue;

@interface MetalContext : NSObject

@property (strong) id<MTLDevice> device;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLCommandQueue> commandQueue;

+(instancetype)shareMetalContext;

+ (instancetype)newContext;

- (id<MTLTexture>) textureFromPixelBuffer:(CVPixelBufferRef)videoPixelBuffer;

- (id<MTLBuffer>) bufferWithF16PixelBuffer:(CVPixelBufferRef)f16PixelBuffer;

@end
