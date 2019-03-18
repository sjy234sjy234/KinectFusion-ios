//
//  MatrixMultiplication.m
//  Scanner
//
//  Created by  沈江洋 on 15/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "MatrixMultiplication.h"

@interface MatrixMultiplication ()

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLBuffer> aMatrixBuffer;

@property (nonatomic, strong) id<MTLBuffer> bMatrixBuffer;

@property (nonatomic, strong) id<MTLBuffer> cMatrixBuffer;

@end

@implementation MatrixMultiplication

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
    }
    return self;
}

- (void)computeWithM: (uint) M andN: (uint)N andK: (uint)K
{
    NSLog(@"computeWith: %d, %d, %d", M, N, K);
    
    _aMatrixBuffer = [_metalContext.device newBufferWithLength:M*N*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    _bMatrixBuffer = [_metalContext.device newBufferWithLength:N*K*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    _cMatrixBuffer = [_metalContext.device newBufferWithLength:M*K*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    void *baseAddress;
    float * floatAddress;
    
    baseAddress = [_aMatrixBuffer contents];
    floatAddress=(float*)baseAddress;
    for(int i=0;i<M;++i)
    {
        for(int j=0;j<N;++j)
        {
            floatAddress[i*N+j]=i+1;
            NSLog(@"A(%d, %d): %f", i, j, floatAddress[i*N+j]);
        }
    }
    
    baseAddress = [_bMatrixBuffer contents];
    floatAddress=(float*)baseAddress;
    for(int i=0;i<N;++i)
    {
        for(int j=0;j<K;++j)
        {
            floatAddress[i*K+j]=i+1;
            NSLog(@"B(%d, %d): %f", i, j, floatAddress[i*K+j]);
        }
    }
    
    baseAddress = [_cMatrixBuffer contents];
    floatAddress=(float*)baseAddress;
    for(int i=0;i<M;++i)
    {
        for(int j=0;j<K;++j)
        {
            NSLog(@"before C(%d, %d): %f", i, j, floatAddress[i*K+j]);
        }
    }
    
    MPSMatrixDescriptor *aMatrixDescriptor= [MPSMatrixDescriptor matrixDescriptorWithRows:M columns:N rowBytes:N*sizeof(float) dataType:MPSDataTypeFloat32];
    MPSMatrixDescriptor *bMatrixDescriptor= [MPSMatrixDescriptor matrixDescriptorWithRows:N columns:K rowBytes:K*sizeof(float) dataType:MPSDataTypeFloat32];
    MPSMatrixDescriptor *cMatrixDescriptor= [MPSMatrixDescriptor matrixDescriptorWithRows:M columns:K rowBytes:K*sizeof(float) dataType:MPSDataTypeFloat32];
    
    MPSMatrix *aMatrix = [[MPSMatrix alloc] initWithBuffer:_aMatrixBuffer descriptor:aMatrixDescriptor];
    MPSMatrix *bMatrix = [[MPSMatrix alloc] initWithBuffer:_bMatrixBuffer descriptor:bMatrixDescriptor];
    MPSMatrix *cMatrix = [[MPSMatrix alloc] initWithBuffer:_cMatrixBuffer descriptor:cMatrixDescriptor];
    
    MPSMatrixMultiplication *sgemmKernel = [[MPSMatrixMultiplication alloc] initWithDevice:_metalContext.device transposeLeft:false transposeRight:false resultRows:M resultColumns:K interiorColumns:N alpha:1.0 beta:0.0];
    
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    
    [sgemmKernel encodeToCommandBuffer:commandBuffer leftMatrix:aMatrix rightMatrix:bMatrix resultMatrix:cMatrix];
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    baseAddress = [_cMatrixBuffer contents];
    floatAddress=(float*)baseAddress;
    
    for(int i=0;i<M;++i)
    {
        for(int j=0;j<K;++j)
        {
            NSLog(@"after C(%d, %d): %f", i, j, floatAddress[i*K+j]);
        }
    }
}

@end
