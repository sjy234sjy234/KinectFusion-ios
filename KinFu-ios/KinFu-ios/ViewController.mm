//
//  ViewController.m
//  KinFu-ios
//
//  Created by  沈江洋 on 2019/1/11.
//  Copyright © 2019  沈江洋. All rights reserved.
//

#import "ViewController.h"

#import "MetalContext.h"
#import "MetalView.h"
#import "TextureRenderer.h"
#import "MathUtilities.hpp"
#import "FusionProcessor.h"

@interface ViewController ()<NSStreamDelegate>
{
    BOOL m_isFusionComplete;
    int m_fusionFrameIndex;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MetalView *mainMetalView;
@property (nonatomic, strong) TextureRenderer *scanningRenderer;
@property (nonatomic, strong) FusionProcessor *fusionProcessor;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSString *streamPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.mainMetalView=[[MetalView alloc] init];
    self.mainMetalView.frame=CGRectMake(0, 0, 375, 500);
    [self.view addSubview:self.mainMetalView];
    
    self.metalContext=[MetalContext shareMetalContext];
    
    self.scanningRenderer=[[TextureRenderer alloc] initWithLayer:self.mainMetalView.metalLayer andContext:_metalContext];
    
    self.fusionProcessor = [FusionProcessor shareFusionProcessorWithContext: _metalContext];
    [self.fusionProcessor setRenderBackColor: {24.0 / 255, 31.0 / 255, 50.0 / 255, 1}];
    simd::float4 cube = {-107.080887, -96.241348, -566.015991, 223.474106};
    [self.fusionProcessor setupTsdfParameterWithCube: cube];
    
    NSString *resourcepath = [[NSBundle mainBundle] resourcePath];
    self.streamPath = [resourcepath stringByAppendingString:@"/depth.bin"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    m_fusionFrameIndex = 0;
    m_isFusionComplete = NO;
    [self setUpStreamForFile: self.streamPath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpStreamForFile:(NSString *)path {
    // iStream is NSInputStream instance variable
    self.inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            //read every frame from depth.bin, which contains one single disparity frame of 640 x 480 x float16,
            //we can easily derive depth from disparity: depth = 1.0 / disparity;
            int frameLen = PORTRAIT_WIDTH * PORTRAIT_HEIGHT * 2;
            uint8_t* buf = new uint8_t[frameLen];
            unsigned int len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:frameLen];
            if(len == frameLen)
            {
                BOOL isFusionOK = [self.fusionProcessor processDisparityData:buf withIndex:m_fusionFrameIndex withTsdfUpdate: YES];
                if(isFusionOK)
                {
                    id<MTLTexture> textureAfterFusion=[self.fusionProcessor getColorTexture];
                    [self.scanningRenderer render: textureAfterFusion];
                    m_fusionFrameIndex++;
                }
                else
                {
                    NSLog(@"Fusion Failed");
                }
            }
            delete buf;
            break;
        }
        default:
            if(m_fusionFrameIndex > 0)
            {
                m_isFusionComplete = YES;
            }
    }
}

- (IBAction)onResetScan:(id)sender {
    if(m_isFusionComplete)
    {
        m_fusionFrameIndex = 0;
        m_isFusionComplete = NO;
        [self setUpStreamForFile: self.streamPath];
    }
}

@end
