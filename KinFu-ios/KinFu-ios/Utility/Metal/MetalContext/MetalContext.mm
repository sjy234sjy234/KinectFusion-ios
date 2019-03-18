#import "MetalContext.h"
#import <Metal/Metal.h>

@implementation MetalContext

static MetalContext *_instance;
+(instancetype)shareMetalContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] initWithDevice:nil];
        }
    });
    return _instance;
}

+ (instancetype)newContext
{
    return [[self alloc] initWithDevice:nil];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        _device = device ?: MTLCreateSystemDefaultDevice();
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

- (id<MTLTexture>) textureFromPixelBuffer:(CVPixelBufferRef)videoPixelBuffer
{
    id<MTLTexture> texture = nil;
    {
        size_t width = CVPixelBufferGetWidth(videoPixelBuffer);
        size_t height = CVPixelBufferGetHeight(videoPixelBuffer);
        MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
        CVMetalTextureCacheRef textureCache;
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _device, nil, &textureCache);
        CVMetalTextureRef metalTextureRef = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, videoPixelBuffer, NULL, pixelFormat, width, height, 0, &metalTextureRef);
        if(status == kCVReturnSuccess)
        {
            texture = CVMetalTextureGetTexture(metalTextureRef);
            CFRelease(metalTextureRef);
            CFRelease(textureCache);
        }
    }
    return texture;
}

- (id<MTLBuffer>)bufferWithF16PixelBuffer:(CVPixelBufferRef)f16PixelBuffer
{
    id<MTLBuffer> buffer;
    
    size_t width = CVPixelBufferGetWidth(f16PixelBuffer);
    size_t height = CVPixelBufferGetHeight(f16PixelBuffer);
    
    CVPixelBufferLockBaseAddress(f16PixelBuffer,  0);
    
    void *baseAddress=CVPixelBufferGetBaseAddress(f16PixelBuffer);
    float16_t *float16Address = (float16_t *)(baseAddress);
    
    buffer = [self.device newBufferWithBytes:float16Address
                                               length:width*height*2
                                              options:MTLResourceOptionCPUCacheModeDefault];
    
    CVPixelBufferUnlockBaseAddress(f16PixelBuffer, 0);
    
    return buffer;
}

@end
