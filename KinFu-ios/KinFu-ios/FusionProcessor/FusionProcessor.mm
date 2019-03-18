//
//  FusionProcessor.m
//  Scanner
//
//  Created by  沈江洋 on 2018/8/24.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FusionProcessor.h"

#import "FuDisparityToDepth.h"
#import "FuTextureToDepth.h"
#import "FuPyramidDepthMap.h"
#import "FuDepthToVertex.h"
#import "FuVertexToNormal.h"
#import "FuTsdfFusioner.h"
#import "FuMCubeTraverse.h"
#import "FuMCubeExtract.h"
#import "FuMeshToTexture.h"
#import "FuICPPrepareMatrix.h"
#import "FuICPReduceMatrix.h"

#import "MathUtilities.hpp"



@interface FusionProcessor ()

//metal context
@property (nonatomic, strong) MetalContext *metalContext;

//compute kernel

@property (nonatomic) FuDisparityToDepth *fuDisparityToDepth;
@property (nonatomic) FuTextureToDepth *fuTextureToDepth;
@property (nonatomic) FuPyramidDepthMap *fuPyramidDepthMap;
@property (nonatomic) FuDepthToVertex *fuDepthToVertex;
@property (nonatomic) FuVertexToNormal *fuVertexToNormal;
@property (nonatomic) FuTsdfFusioner *fuTsdfFusioner;
@property (nonatomic) FuMCubeTraverse *fuMCubeTraverse;
@property (nonatomic) FuMCubeExtract *fuMCubeExtract;
@property (nonatomic) FuMeshToTexture *fuMeshToTexture;
@property (nonatomic) FuICPPrepareMatrix *fuICPPrepareMatrix;
@property (nonatomic) FuICPReduceMatrix *fuICPReduceMatrix;
@end

@implementation FusionProcessor
{
    id<MTLBuffer> m_currentDepthMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_currentVertexMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_currentNormalMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_preDepthMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_preVertexMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_preNormalMapPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_icpLeftMatrixPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_icpRightMatrixPyramid[PYRAMID_LEVEL];
    id<MTLBuffer> m_icpLeftReduceBuffer;
    id<MTLBuffer> m_icpRightReduceBuffer;
    id<MTLBuffer> m_tsdfVertexBuffer;
    id<MTLBuffer> m_mCubeActiveVoxelInfoBuffer;
    id<MTLBuffer> m_mCubeExtractPointBuffer;
    id<MTLBuffer> m_mCubeExtractNormalBuffer;
    
    id<MTLTexture> m_colorTexture;
    id<MTLTexture> m_depthTexture;
    TsdfParameter m_tsdfParameter;
    MCubeParameter m_mCubeParameter;
    IntrinsicUVD2XYZ m_intrinsicUVD2XYZ[PYRAMID_LEVEL];
    IntrinsicXYZ2UVD m_intrinsicXYZ2UVD[PYRAMID_LEVEL];
    CameraNDC2Depth m_cameraNDC2Depth;
    ICPThreshold m_icpThreshold;
    simd::float4x4 m_projectionTransform;
    simd::float4x4 m_frameToGlobalTransform;
    simd::float4x4 m_globalToFrameTransform;
}

static FusionProcessor *_instance;
+(instancetype)shareFusionProcessorWithContext: (MetalContext *)context
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[FusionProcessor alloc] initWithContext:context];
        }
    });
    return _instance;
}

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        
        _fuDisparityToDepth = [[FuDisparityToDepth alloc] initWithContext: _metalContext];
        _fuTextureToDepth = [[FuTextureToDepth alloc] initWithContext: _metalContext];
        _fuPyramidDepthMap = [[FuPyramidDepthMap alloc] initWithContext: _metalContext];
        _fuDepthToVertex = [[FuDepthToVertex alloc] initWithContext: _metalContext];
        _fuVertexToNormal = [[FuVertexToNormal alloc] initWithContext: _metalContext];
        _fuTsdfFusioner=[[FuTsdfFusioner alloc] initWithContext:_metalContext];
        _fuMCubeTraverse=[[FuMCubeTraverse alloc] initWithContext:_metalContext];
        _fuMCubeExtract=[[FuMCubeExtract alloc] initWithContext:_metalContext];
        _fuMeshToTexture=[[FuMeshToTexture alloc] initWithContext:_metalContext];
        _fuICPPrepareMatrix= [[FuICPPrepareMatrix alloc] initWithContext:_metalContext];
        _fuICPReduceMatrix=[[FuICPReduceMatrix alloc] initWithContext:_metalContext];
        [self buildResources];
    }
    return self;
}

- (void) reset
{
    simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    m_frameToGlobalTransform=simd::float4x4(onesFloat4);
    m_globalToFrameTransform=simd::inverse(m_frameToGlobalTransform);
    memset(m_tsdfVertexBuffer.contents, 0, m_tsdfVertexBuffer.length);
}

- (void)buildResources
{
    size_t width=PORTRAIT_WIDTH;
    size_t height=PORTRAIT_HEIGHT;
    
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage=MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget;
    m_colorTexture=[_metalContext.device newTextureWithDescriptor:textureDescriptor];
    textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    m_depthTexture=[_metalContext.device newTextureWithDescriptor:textureDescriptor];
    
    for(uint i=0;i<PYRAMID_LEVEL;++i)
    {
        m_currentDepthMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        m_currentVertexMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float)*3 options:MTLResourceOptionCPUCacheModeDefault];
        m_currentNormalMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float)*3 options:MTLResourceOptionCPUCacheModeDefault];
        
        m_preDepthMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        m_preVertexMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float)*3 options:MTLResourceOptionCPUCacheModeDefault];
        m_preNormalMapPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float)*3 options:MTLResourceOptionCPUCacheModeDefault];
        
        m_icpLeftMatrixPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float)*6 options:MTLResourceOptionCPUCacheModeDefault];
        m_icpRightMatrixPyramid[i]=[_metalContext.device newBufferWithLength:width*height*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        
        width=width>>1;
        height=height>>1;
    }
    
    m_icpLeftReduceBuffer=[_metalContext.device newBufferWithLength:6*6*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    m_icpRightReduceBuffer=[_metalContext.device newBufferWithLength:6*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    size_t tsdfVoxelNumber=TSDF_RESOLUTION*TSDF_RESOLUTION*TSDF_RESOLUTION;
    m_tsdfVertexBuffer=[_metalContext.device newBufferWithLength:tsdfVoxelNumber*sizeof(TsdfVertex) options:MTLResourceOptionCPUCacheModeDefault];
    
    uint maxOccupyVoxelNumber=tsdfVoxelNumber*MCUBE_ACTIVE_RATIO;
    m_mCubeParameter={MCUBE_ISOVALUE,maxOccupyVoxelNumber,MCUBE_MIN_WEIGHT,MCUBE_TABLE_WIDTH,MCUBE_TABLE_HEIGHT};
    m_mCubeActiveVoxelInfoBuffer=[_metalContext.device newBufferWithLength:maxOccupyVoxelNumber*sizeof(ActiveVoxelInfo) options:MTLResourceOptionCPUCacheModeDefault];
    
    for(int i=0;i<PYRAMID_LEVEL;++i)
    {
        int div=1<<i;
        float focal=CAMERA_FOCAL/div;
        float focalInvert=1/focal;
        float centerU=0.5*(PORTRAIT_WIDTH-1)/div;
        float centerV=0.5*(PORTRAIT_HEIGHT-1)/div;
        m_intrinsicUVD2XYZ[i]={focalInvert,centerU,centerV};
        m_intrinsicXYZ2UVD[i]={focal,centerU,centerV};
    }
    
    float tsdfOriginX=-0.5*(TSDF_RESOLUTION-1)*TSDF_PERLENGTH;
    float tsdfOriginY=-0.5*(TSDF_RESOLUTION-1)*TSDF_PERLENGTH;
    float tsdfOriginZ=-TSDF_NEAREST-1.0*(TSDF_RESOLUTION-1)*TSDF_PERLENGTH;
    m_tsdfParameter={tsdfOriginX, tsdfOriginY, tsdfOriginZ, TSDF_PERLENGTH, TSDF_TRUNCATE, TSDF_MAXWEIGHT, TSDF_RESOLUTION};
    
    float cameraNear=CAMERA_NEAR;
    float cameraFar=CAMERA_FAR;
    float param1=2.0*cameraNear*cameraFar/(cameraNear-cameraFar);
    float param2=(cameraNear+cameraFar)/(cameraNear-cameraFar);
    m_cameraNDC2Depth={param1, param2};
    
    float maxDistance=ICP_MAX_DISTANCE;
    float maxAngleSin=sin(ICP_MAX_ANGLE*M_PI/180.0);
    m_icpThreshold={maxDistance, maxAngleSin};
    
    m_projectionTransform = matrix_float4x4_perspective((float)PORTRAIT_WIDTH/PORTRAIT_HEIGHT, CAMERA_FOV*M_PI/180.0, CAMERA_NEAR, CAMERA_FAR);
    
    simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    m_frameToGlobalTransform=simd::float4x4(onesFloat4);
    m_globalToFrameTransform=simd::inverse(m_frameToGlobalTransform);
}

- (void) setupTsdfParameterWithCube: (const simd::float4) cube
{
    float tsdfPerLength=(cube.w)/(TSDF_RESOLUTION-1);
    float tsdfTruncate=tsdfPerLength*5;
    m_tsdfParameter = {cube.x, cube.y, cube.z, tsdfPerLength, tsdfTruncate, TSDF_MAXWEIGHT, TSDF_RESOLUTION};
}

- (BOOL) processDisparityData: (uint8_t *)disparityData withIndex: (int) fusionFrameIndex withTsdfUpdate:(BOOL)isTsdfUpdate
{
    id<MTLBuffer> inDisparityMapBuffer = [_metalContext.device newBufferWithBytes:disparityData
                                                                           length:PORTRAIT_WIDTH*PORTRAIT_HEIGHT*2
                                                                          options:MTLResourceOptionCPUCacheModeDefault];
    return [self processFrame: inDisparityMapBuffer withIndex: fusionFrameIndex withTsdfUpdate: isTsdfUpdate];
}

- (BOOL) processDisparityPixelBuffer: (CVPixelBufferRef)disparityPixelBuffer withIndex: (int) fusionFrameIndex withTsdfUpdate:(BOOL)isTsdfUpdate
{
    id<MTLBuffer> inDisparityMapBuffer = [_metalContext bufferWithF16PixelBuffer: disparityPixelBuffer];
    return [self processFrame: inDisparityMapBuffer withIndex: fusionFrameIndex withTsdfUpdate: isTsdfUpdate];
}

- (BOOL) processFrame: (id<MTLBuffer>) inDisparityMapBuffer withIndex: (int) fusionFrameIndex withTsdfUpdate:(BOOL)isTsdfUpdate;
{
    //pre-process
    [_fuMeshToTexture drawPoints: m_mCubeExtractPointBuffer normals: m_mCubeExtractNormalBuffer intoColorTexture: m_colorTexture andDepthTexture: m_depthTexture withTransform: m_projectionTransform * m_globalToFrameTransform];
    [_fuTextureToDepth compute: m_depthTexture intoTexture: m_preDepthMapPyramid[0] with: m_cameraNDC2Depth];
    [_fuDisparityToDepth compute: inDisparityMapBuffer intoDepthMapBuffer: m_currentDepthMapPyramid[0]];
    for(int level=1;level<PYRAMID_LEVEL;++level)
    {
        [_fuPyramidDepthMap compute: m_currentDepthMapPyramid[level - 1] intoDepthMapBuffer: m_currentDepthMapPyramid[level] withLevel: level];
        [_fuPyramidDepthMap compute: m_preDepthMapPyramid[level - 1] intoDepthMapBuffer: m_preDepthMapPyramid[level] withLevel: level];
    }
    for(int level=0;level<PYRAMID_LEVEL;++level)
    {
        [_fuDepthToVertex compute: m_currentDepthMapPyramid[level] intoVertexMapBuffer: m_currentVertexMapPyramid[level] withLevel: level andIntrinsicUVD2XYZ: m_intrinsicUVD2XYZ[level]];
        [_fuVertexToNormal compute: m_currentVertexMapPyramid[level] intoNormalMapBuffer: m_currentNormalMapPyramid[level] withLevel: level];
        [_fuDepthToVertex compute: m_preDepthMapPyramid[level] intoVertexMapBuffer: m_preVertexMapPyramid[level] withLevel: level andIntrinsicUVD2XYZ: m_intrinsicUVD2XYZ[level]];
        [_fuVertexToNormal compute: m_preVertexMapPyramid[level] intoNormalMapBuffer: m_preNormalMapPyramid[level] withLevel: level];
    }
    
    //icp
    if(fusionFrameIndex<=0)
    {
        //first frame, no icp
        NSLog(@"first frame, fusion reset");
        [self reset];
    }
    else
    {
        //icp iteration
        BOOL isSolvable=YES;
        simd::float3x3 currentF2gRotate;
        simd::float3 currentF2gTranslate;
        simd::float3x3 preF2gRotate;
        simd::float3 preF2gTranslate;
        simd::float3x3 preG2fRotate;
        simd::float3 preG2fTranslate;
        matrix_transform_extract(m_frameToGlobalTransform,currentF2gRotate,currentF2gTranslate);
        matrix_transform_extract(m_frameToGlobalTransform, preF2gRotate, preF2gTranslate);
        matrix_transform_extract(m_globalToFrameTransform, preG2fRotate, preG2fTranslate);
        for(int level=PYRAMID_LEVEL-1;level>=0;--level)
        {
            uint iteratorNumber=ICPIteratorNumber[level];
            for(int it=0;it<iteratorNumber;++it)
            {
                uint occupiedPixelNumber = [_fuICPPrepareMatrix computeCurrentVMap:m_currentVertexMapPyramid[level] andCurrentNMap:m_currentNormalMapPyramid[level] andPreVMap:m_preVertexMapPyramid[level] andPreNMap:m_preNormalMapPyramid[level] intoLMatrix:m_icpLeftMatrixPyramid[level] andRMatrix:m_icpRightMatrixPyramid[level] withCurrentR:currentF2gRotate andCurrentT:currentF2gTranslate andPreF2gR:preF2gRotate andPreF2gT:preF2gTranslate andPreG2fR:preG2fRotate andPreG2fT:preG2fTranslate  andThreshold:m_icpThreshold andIntrinsicXYZ2UVD:m_intrinsicXYZ2UVD[level] withLevel:level];
                if(occupiedPixelNumber==0)
                {
                    isSolvable=NO;
                }
                if(isSolvable)
                {
                    [_fuICPReduceMatrix computeLeftMatrix:m_icpLeftMatrixPyramid[level] andRightmatrix:m_icpRightMatrixPyramid[level] intoLeftReduce:m_icpLeftReduceBuffer andRightReduce:m_icpRightReduceBuffer withLevel:level andOccupiedNumber:occupiedPixelNumber];
                    float result[6];
                    isSolvable=matrix_float6x6_solve((float*)m_icpLeftReduceBuffer.contents, (float*)m_icpRightReduceBuffer.contents, result);
                    if(isSolvable)
                    {
                        simd::float3x3 rotateIncrement=matrix_float3x3_rotation(result[0], result[1], result[2]);
                        simd::float3 translateIncrement={result[3], result[4], result[5]};
                        currentF2gRotate=rotateIncrement*currentF2gRotate;
                        currentF2gTranslate=rotateIncrement*currentF2gTranslate+translateIncrement;
                    }
                }
            }
            if(!isSolvable)
            {
                break;
            }
        }
        if(isSolvable)
        {
            matrix_transform_compose(m_frameToGlobalTransform, currentF2gRotate, currentF2gTranslate);
            m_globalToFrameTransform=simd::inverse(m_frameToGlobalTransform);
        }
        else
        {
            NSLog(@"lost frame");
            return NO;
        }
    }
    
    if(isTsdfUpdate||fusionFrameIndex<=0)
    {
        //tsdf fusion updater
        [_fuTsdfFusioner compute:m_currentDepthMapPyramid[0] intoTsdfVertexBuffer:m_tsdfVertexBuffer withIntrinsicXYZ2UVD:m_intrinsicXYZ2UVD[0] andTsdfParameter:m_tsdfParameter andTransform:m_globalToFrameTransform];
        
        //marching cube
        int activeVoxelNumber = [_fuMCubeTraverse compute:m_tsdfVertexBuffer intoActiveVoxelInfo:m_mCubeActiveVoxelInfoBuffer withMCubeParameter:m_mCubeParameter];
        if(activeVoxelNumber==0)
        {
            NSLog(@"alert: no active voxel");
            m_mCubeExtractPointBuffer = nil;
            m_mCubeExtractNormalBuffer = nil;
            return NO;
        }
        else if(activeVoxelNumber>=m_mCubeParameter.maxActiveNumber)
        {
            NSLog(@"alert: too mush active voxels");
            m_mCubeExtractPointBuffer = nil;
            m_mCubeExtractNormalBuffer = nil;
            return NO;
        }
        else
        {
            void *baseAddress=m_mCubeActiveVoxelInfoBuffer.contents;
            ActiveVoxelInfo *activeVoxelInfo=(ActiveVoxelInfo*)baseAddress;
            for(int i=1;i<activeVoxelNumber;++i)
            {
                activeVoxelInfo[i].vertexNumber=activeVoxelInfo[i-1].vertexNumber+activeVoxelInfo[i].vertexNumber;
            }
            uint totalVertexNumber=activeVoxelInfo[activeVoxelNumber-1].vertexNumber;
            m_mCubeExtractPointBuffer = [_metalContext.device newBufferWithLength: 3 * totalVertexNumber * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            m_mCubeExtractNormalBuffer = [_metalContext.device newBufferWithLength: 3 * totalVertexNumber * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            [_fuMCubeExtract compute: m_mCubeActiveVoxelInfoBuffer andTsdfVertexBuffer: m_tsdfVertexBuffer withActiveVoxelNumber: activeVoxelNumber andTsdfParameter: m_tsdfParameter andMCubeParameter: m_mCubeParameter andOutMCubeExtractPointBufferT: m_mCubeExtractPointBuffer andOutMCubeExtractNormalBuffer: m_mCubeExtractNormalBuffer];
        }
    }
    
    return YES;
}

- (id<MTLBuffer>) getExtractPointBuffer
{
    return m_mCubeExtractPointBuffer;
}

- (id<MTLBuffer>) getExtractNormalBuffer
{
    return m_mCubeExtractNormalBuffer;
}

- (id<MTLTexture>) getColorTexture
{
    return m_colorTexture;
}

- (float) getQuternionY
{
    float4 quaternion;
    matrix_quaternion_angle(m_globalToFrameTransform, quaternion);
    return quaternion.y;
}

- (void)setRenderBackColor:(const simd::float4) color
{
    [_fuMeshToTexture setClearColor: MTLClearColorMake(color.x, color.y, color.z, color.w)];
}

@end

