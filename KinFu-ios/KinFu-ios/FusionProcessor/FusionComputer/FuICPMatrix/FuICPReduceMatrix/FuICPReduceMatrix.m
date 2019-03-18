//
//  FuICPReduceMatrix.m
//  Scanner
//
//  Created by  沈江洋 on 16/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FuICPReduceMatrix.h"

@interface FuICPReduceMatrix ()

@property (nonatomic, strong) MetalContext *metalContext;

@end

@implementation FuICPReduceMatrix

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
    }
    return self;
}

- (void)computeLeftMatrix:(id<MTLBuffer>)leftMatrixBuffer andRightmatrix: (id<MTLBuffer>)rightMatrixBuffer intoLeftReduce: (id<MTLBuffer>)leftReduceBuffer andRightReduce:(id<MTLBuffer>)rightReduceBuffer withLevel: (uint) level andOccupiedNumber: (uint)occupiedPixelNumber
{
    if(!leftMatrixBuffer||!rightMatrixBuffer||!leftReduceBuffer||!rightReduceBuffer){
        return;
    }
    
    uint matrixRows=occupiedPixelNumber;
    
    id<MTLCommandBuffer> commandBuffer;
    MPSMatrixMultiplication *sgemmKernel;
    
    MPSMatrixDescriptor *matrixDescriptor;
    MPSMatrix *aMatrix;
    MPSMatrix *bMatrix;
    MPSMatrix *cMatrix;
    
    matrixDescriptor = [MPSMatrixDescriptor matrixDescriptorWithRows:matrixRows columns:6 rowBytes:6*sizeof(float) dataType:MPSDataTypeFloat32];
    aMatrix=[[MPSMatrix alloc] initWithBuffer:leftMatrixBuffer descriptor:matrixDescriptor];
    
    matrixDescriptor.rows=matrixRows;
    matrixDescriptor.columns=1;
    matrixDescriptor.rowBytes=sizeof(float);
    bMatrix=[[MPSMatrix alloc] initWithBuffer:rightMatrixBuffer descriptor:matrixDescriptor];
    
    matrixDescriptor.rows=6;
    matrixDescriptor.columns=6;
    matrixDescriptor.rowBytes=6*sizeof(float);
    cMatrix=[[MPSMatrix alloc] initWithBuffer:leftReduceBuffer descriptor:matrixDescriptor];
    
    sgemmKernel = [[MPSMatrixMultiplication alloc] initWithDevice:_metalContext.device transposeLeft:true transposeRight:false resultRows:6 resultColumns:6 interiorColumns:matrixRows alpha:1.0 beta:0.0];
    commandBuffer = [_metalContext.commandQueue commandBuffer];
    [sgemmKernel encodeToCommandBuffer:commandBuffer leftMatrix:aMatrix rightMatrix:aMatrix resultMatrix:cMatrix];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    matrixDescriptor.rows=6;
    matrixDescriptor.columns=1;
    matrixDescriptor.rowBytes=sizeof(float);
    cMatrix=[[MPSMatrix alloc] initWithBuffer:rightReduceBuffer descriptor:matrixDescriptor];
    sgemmKernel = [[MPSMatrixMultiplication alloc] initWithDevice:_metalContext.device transposeLeft:true transposeRight:false resultRows:6 resultColumns:1 interiorColumns:matrixRows alpha:1.0 beta:0.0];
    commandBuffer = [_metalContext.commandQueue commandBuffer];
    [sgemmKernel encodeToCommandBuffer:commandBuffer leftMatrix:aMatrix rightMatrix:bMatrix resultMatrix:cMatrix];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
//    void *leftBaseAddress=leftReduceBuffer.contents;
//    float *leftFloatAddress=(float*)leftBaseAddress;
//    NSLog(@"leftReduceBuffer:");
//    for(int i=0;i<6;++i)
//    {
//        NSLog(@"row %d: %f, %f, %f, %f, %f, %f", i, leftFloatAddress[i*6+0], leftFloatAddress[i*6+1], leftFloatAddress[i*6+2], leftFloatAddress[i*6+3], leftFloatAddress[i*6+4], leftFloatAddress[i*6+5]);
//    }
//
//    void *rightBaseAddress=rightReduceBuffer.contents;
//    float *rightFloatAddress=(float*)rightBaseAddress;
//    NSLog(@"rightReduceBuffer:");
//    NSLog(@"%f, %f, %f, %f, %f, %f", rightFloatAddress[0], rightFloatAddress[1], rightFloatAddress[2], rightFloatAddress[3], rightFloatAddress[4], rightFloatAddress[5]);
}

@end
