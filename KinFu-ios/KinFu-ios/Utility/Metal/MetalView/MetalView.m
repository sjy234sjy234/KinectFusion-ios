#import "MetalView.h"

@implementation MetalView

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (CAMetalLayer *)metalLayer
{
    return (CAMetalLayer *)self.layer;
}

- (instancetype)init
{
    self = [super init];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    [self addGestureRecognizer:pinch];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    [self addGestureRecognizer:pinch];
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _currentTouch = [touches anyObject];
    if([self.delegate respondsToSelector:@selector(onTouchesBegan:)])
    {
        UITouch *touch=[touches anyObject];
        CGPoint absolute=[touch locationInView:self];
        CGPoint relative;
        relative.x=absolute.x/self.frame.size.width;
        relative.y=absolute.y/self.frame.size.height;
        [self.delegate onTouchesBegan:relative];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _currentTouch = nil;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _currentTouch = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _currentTouch = [touches anyObject];
    if([self.delegate respondsToSelector:@selector(onTouchesMoved:)])
    {
        UITouch *touch=[touches anyObject];
        CGPoint current=[touch locationInView:self];
        CGPoint previous=[touch previousLocationInView:self];
        CGPoint offset=CGPointMake(current.x-previous.x, current.y-previous.y);
        if(offset.x!=0.0||offset.y!=0.0)
        {
            [self.delegate onTouchesMoved:offset];
        }
    }
}

- (void)onPinch: (UIPinchGestureRecognizer *)sender
{
    if([self.delegate respondsToSelector:@selector(onPinch:)])
    {
        static float lastScale=1.0;
        
        if([sender state]==UIGestureRecognizerStateEnded)
        {
            lastScale=1.0;
            return;
        }
        
        float scale = [sender scale];
        if(scale<lastScale)
        {
            [self.delegate onPinch:YES];
        }
        else if(scale>lastScale)
        {
            [self.delegate onPinch:NO];
        }
        lastScale=scale;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // If we've moved to a window by the time our frame is being set, we can take its scale as our own
    if (self.window)
    {
        scale = self.window.screen.scale;
    }
    
    CGSize drawableSize = self.bounds.size;
    
    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    
    self.metalLayer.drawableSize = drawableSize;
}

@end

