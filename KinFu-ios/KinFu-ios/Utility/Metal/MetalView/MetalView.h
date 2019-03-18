#import <UIKit/UIKit.h>

@protocol MetalViewDelegate <NSObject>

- (void)onTouchesBegan:(CGPoint) pos;

- (void)onTouchesMoved: (CGPoint) offset;

- (void)onPinch: (BOOL) isZoomOut;

@end

@interface MetalView : UIView

@property (nonatomic, assign) id<MetalViewDelegate> delegate;

@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, readonly) UITouch *currentTouch;

@end
