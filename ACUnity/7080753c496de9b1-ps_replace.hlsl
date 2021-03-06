// Gigantic 1000 line shader for shadows.

// Compile now after manual fixes, but does not generate code for the ld_structured_indexable sections,
// the compiler deems those as never reached and stripped.
// unknown how to fix at moment.

// In current state, seems to introduce squares where some shadows should be.

cbuffer cb_g_Frame : register(b1)
{

  struct FrameConsts
  {
    float4 m_CurrentTime;
    bool m_DeconstructionEnabled;
    float4 m_DeconstructionRanges;
    float4 m_DeconstructionOrigin;
    float4 m_GlobalWind;
    float4 m_WeatherInfo;
    float4 m_SkyVisibilityWetnessBias;
    float4 m_MainPlayerPosition;

    struct 
    {
      float4 m_ShadowMapSize;
      float4 m_Offsets[4];
      float4 m_Scales[4];
      float4 m_SplitBlendMulAddUVAndZ[4];
      float4 m_NoiseScale;
      float4 m_NearFar;
      float4 m_FadeParams;
      float4 m_CascadesRangesMax;
      float4 m_CascadesRangesMin;
      float4 m_ShadowSplitBlendUVAmount;
      float4x4 m_WorldToLightProj;
      float4x4 m_FarWorldToLightProj;
      float4x4 m_DebugShadowVisiblePixelMat;
    } m_SunShadows;


    struct 
    {
      float4 m_Direction;
      float4 m_Color;
    } m_SunLight;


    struct 
    {
      float4 Params;
      float4 WSToIndirectionScale;
      float4 WSToIndirectionBias;
      float4 InvVolumeSize;
      float4 InvVolumeAtlasSize;
    } m_GIConsts;

    float4 m_LocalCubeMapParams[2];

    struct
    {
      float4 boxMax;
      float4 boxMin;
      float4 innerBlendBoxMax;
      float4 blendBoxMax;
      float4 worldPosition;
      float4x4 worldToLocal;
      uint cubeMapArrayIndex;
      float padding;
    } m_LocalCubeMaps[32];


    struct
    {
      float4 VolumeInvTransZ;
      float4 VolumeTexScale;
      float4 VolumeTexBias;
      float4 SunColor;
      float4 SunColorByOneOverPi;
    } m_VolumetricFog;


    struct
    {
      float RippleScale;
      float2 SurfaceFloodLevelRef;
      float4 RippleImpactSurfaceSizeInvSize;
    } m_SurfaceWeatherModifications;


    struct
    {
      float4 HeightMapSize;
      float4 HeightMapOffset;
    } m_RainBlockerConsts;

    float4 m_WorldMapFogExtents;
    float4 m_WorldMapFogTextureSize;
    float m_WorldMapFogMinHeight;
    float m_WorldMapFogMaxHeight;
    uint m_WorldMapFogVisibilityFlags;
    float4 m_WorldMapDistrictColors[32];
    float4 m_UILighting[6];
    float m_CharacterEffectMultiplier;
  } g_Frame : packoffset(c0);

}

cbuffer cb_g_Pass : register(b2)
{

  struct 
  {
    float4 m_EyePosition;
    float4 m_EyeDirection;
    float4x4 m_ViewToWorld;
    float4x4 m_WorldToView;
    float4x4 m_ProjMatrix;
    float4x4 m_ViewProj;
    float4x4 m_ViewNoTranslationProj;
    float4 m_ViewTranslation;

    struct
    {
      float4x4 clipXYZToViewPos;
      float4x4 clipXYZToWorldPos;
      float4 clipZToViewZ;
    } reverseProjParams;

    float4 m_VPosToUV;
    float4 m_ViewportScaleOffset;
    float4 m_ClipPlane;
    float4 m_GlobalLightingScale;
    float4 m_ViewSpaceLightingBackWS;
    float4 m_ThinGeomAAPixelScale;
  } g_Pass : packoffset(c0);

}

cbuffer cb_g_DeferredLights : register(b5)
{

  struct
  {

    struct
    {
      float4 m_Position;
      float4 m_Color;
      float4 m_Attenuation;
    } m_OmniLight;


    struct
    {
      float4 m_Direction;
      float4 m_Color;
    } m_DirectLight;


    struct
    {
      float4 m_Position;
      float4 m_Color;
      float4 m_Attenuation;
      float4 m_Direction;
      float4 m_ConeAngles;
      float4 m_PositionAtNearClip;
    } m_SpotLight;


    struct
    {
      float4x4 worldToLight[6];
      float4 shadowMapScaleOffset[6];
      float4 noiseScale;
    } m_Projections;


    struct
    {
      float4x4 worldToCookie;
      int4 cookieArrayIndex;
    } m_Cookie;

    float4 m_BackgroundColor;
    float4 m_DepthParams;
    float4 m_EyeXAxis;
    float4 m_EyeYAxis;
    float4 m_EyeZAxis;
    float4 m_VPOSToUVs_Resolve;
    float4 m_EyeWorldPosition_Resolve;
    float4 m_WeatherExposedParams;
    float4x4 m_LightClipToWorldMat;
    float4 m_IsolateVars;
    float m_EnvironmentSpecularScale;
  } g_DeferredLights : packoffset(c0);

}

cbuffer cb_g_VolumeCloudsShadow : register(b10)
{

  struct
  {
    float4 CloudScale;
    float4 CloudTranslate;
    float4 CloudProject;
    float4 UseCloudShadow;
    float4 CloudShadowMipBias;
  } g_VolumeCloudsShadow : packoffset(c0);

}


SamplerState s_g_WorldGIVolumeSampler_s : register(s4);
SamplerState s_LocalCubeMaps_s : register(s8);
SamplerState s_PointClamp_s : register(s10);
SamplerState s_TrilinearClamp_s : register(s12);
SamplerState s_TrilinearWrap_s : register(s13);
SamplerComparisonState s_LinearCmpWithBorder_s : register(s15);
Texture2D<float4> t_Albedo : register(t0);
Texture2D<float4> t_Normals : register(t1);
Texture2D<float4> t_DepthSurface : register(t2);
Texture2D<float4> t_SpecularReflectance : register(t3);
Texture2D<float4> t_SSAO : register(t4);

  // Manual fix TextureCubeArray here
  TextureCubeArray<float4> t_LocalCubeMaps : register(t5);

Texture2D<float4> t_Emissive : register(t12);
TextureCube<float4> t_g_SkyLightingCubeTexture : register(t13);
Texture2D<float4> t_g_ShadowSampler : register(t14);
Texture2D<float4> t_MiscProps : register(t15);
Texture3D<float4> t_g_WorldGIVolume0 : register(t20);
Texture3D<float4> t_g_WorldGIVolume1 : register(t21);
Texture3D<float4> t_g_WorldGIVolume2 : register(t22);
Texture3D<float4> t_g_WorldGIVolume3 : register(t23);
Texture3D<uint> g_WorldGIIndirection : register(t24);
TextureCube<float4> t_GlobalEnvMap : register(t25);

  // Manually fix structured buffer to add missing struct
  StructuredBuffer<float4x4> g_IndoorGIVolumes : register(t26);

  // Manually fix structured buffer to add missing struct
  struct GIIndirectionCell   
  {
      float3 WSToUnitScale;          // Offset:    0
      float3 WSToUnitBias;           // Offset:   12
      float3 UnitToVolumeScale;      // Offset:   24
      float3 UnitToVolumeBias;       // Offset:   36
      float NormalBiasScale;         // Offset:   48
  };                                 // Offset:    0 Size:    52
  StructuredBuffer<GIIndirectionCell> g_WorldGICells : register(t28);

Texture2D<uint> g_VolumeIndex : register(t29);
Buffer<float4> g_GILocalCubeMapsSRV : register(t48);
Texture3D<float4> t_g_CloudShadowTexture : register(t54);
Texture2D<float4> t_BRDFLUT : register(t55);

  // Manually fix structured buffer to add missing struct
struct SkyLightingSH
  {
      float4 Values[7];              // Offset:    0
      float4 SkyLightingUp;          // Offset:  112
      float4 SkyLightingScale;       // Offset:  128
  };                                 // Offset:    0 Size:   144
StructuredBuffer<SkyLightingSH> g_SkySHConstants : register(t56);

Texture2D<float4> StereoParams : register(t125);

void main(
  float4 v0 : SV_Position0,
// manual fix from uint4 to int4.  
int4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24;
  uint4 bitmask;
  r0.xy = g_Pass.m_VPosToUV.xy * v0.xy;
  r1.z = t_DepthSurface.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).x;
  r1.xy = r0.xy * float2(2.000000e+000,-2.000000e+000) + float2(-1.000000e+000,1.000000e+000);
  r1.w = 1.000000000e+000;
  r2.x = dot(r1.xyzw, g_Pass.reverseProjParams.clipXYZToViewPos._m00_m10_m20_m30);
  r2.y = dot(r1.xyzw, g_Pass.reverseProjParams.clipXYZToViewPos._m01_m11_m21_m31);
  r2.z = dot(r1.xyzw, g_Pass.reverseProjParams.clipXYZToViewPos._m02_m12_m22_m32);
  r0.z = dot(r1.xyzw, g_Pass.reverseProjParams.clipXYZToViewPos._m03_m13_m23_m33);
  r1.xyz = r2.xyz / r0.zzz;
  r1.w = 1.000000000e+000;
  r2.x = dot(r1.xyzw, g_Pass.m_ViewToWorld._m00_m10_m20_m30);
  r2.y = dot(r1.xyzw, g_Pass.m_ViewToWorld._m01_m11_m21_m31);
  r2.z = dot(r1.xyzw, g_Pass.m_ViewToWorld._m02_m12_m22_m32);
  r1.xyzw = t_Albedo.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).xyzw;
  r3.xyzw = t_Normals.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).xyzw;
  r4.xyzw = t_SpecularReflectance.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).yxzw;
  r5.xyzw = t_MiscProps.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).xyzw;
  r3.xyz = r3.xyz * float3(2.000000e+000,2.000000e+000,2.000000e+000) + float3(-1.000000e+000,-1.000000e+000,-1.000000e+000);
  r0.z = dot(r3.xyz, r3.xyz);
  r0.z = rsqrt(r0.z);
  r6.xyz = r3.xyz * r0.zzz;
  r0.z = max(r1.w, 9.999999747e-006);
  r0.z = log2(r0.z);
  r0.z = 2.200000048e+000 * r0.z;
  r0.z = exp2(r0.z);
  r0.w = 1.900000000e+001 * r3.w;
  r3.x = exp2(r0.w);
  r0.w = r3.x * 5.000000000e-001 + 1.000000000e+000;
  r7.y = 1.000000e+000 / r0.w;
  r0.w = 2.550000000e+002 * r5.w;
  r0.w = (uint)r0.w;
  r0.w = r0.w == 255;
  if (r0.w != 0) {
    r1.w = 9.999999747e-005 < r4.w;
    r8.xyz = sqrt(r1.xyz);
    r1.xyz = r1.www ? r8.xyz : r1.xyz;
    r8.xyz = r5.xyz * float3(2.000000e+000,2.000000e+000,2.000000e+000) + float3(-1.000000e+000,-1.000000e+000,-1.000000e+000);
    r1.w = dot(r8.xyz, r8.xyz);
    r1.w = rsqrt(r1.w);
    r8.xyz = r8.xyz * r1.www;
    r1.w = 1.900000000e+001 * r4.y;
    r3.y = exp2(r1.w);
    r9.xyz = float3(0.000000e+000,0.000000e+000,0.000000e+000);
    r10.xyz = r0.zzz;
    r11.y = 0.000000000e+000;
    r0.z = 1.000000000e+000;
    r5.xz = float2(0.000000e+000,0.000000e+000);
  } else {
    r9.xyz = t_Emissive.SampleLevel(s_PointClamp_s, r0.xy, 0.000000000e+000).xyz;
    r10.xyz = r4.yxz;
    r8.xyz = float3(1.000000e+000,1.000000e+000,1.000000e+000);
    r1.xyz = float3(0.000000e+000,0.000000e+000,0.000000e+000);
    r11.y = r5.y;
    r3.y = 1.000000000e+000;
    r4.xz = float2(1.000000e+000,0.000000e+000);
  }
  r1.w = r0.w ? r4.x : 1.000000000e+000;
  r0.x = t_SSAO.Sample(s_PointClamp_s, r0.xy).x;
  r4.xyw = g_Pass.m_EyePosition.xyz + -r2.xyz;
  r2.w = 1.000000000e+000;
  r12.x = dot(r2.xyzw, g_Frame.m_SunShadows.m_WorldToLightProj._m00_m10_m20_m30);
  r12.y = dot(r2.xyzw, g_Frame.m_SunShadows.m_WorldToLightProj._m01_m11_m21_m31);
  r12.z = dot(r2.xyzw, g_Frame.m_SunShadows.m_WorldToLightProj._m02_m12_m22_m32);
  r13.xyz = r12.xyz * g_Frame.m_SunShadows.m_Scales[0].xyz + g_Frame.m_SunShadows.m_Offsets[0].xyz;
  r14.xyz = r12.xyz * g_Frame.m_SunShadows.m_Scales[1].xyz + g_Frame.m_SunShadows.m_Offsets[1].xyz;
  r15.xyz = r12.xyz * g_Frame.m_SunShadows.m_Scales[2].xyz + g_Frame.m_SunShadows.m_Offsets[2].xyz;
  r12.xyz = r12.xyz * g_Frame.m_SunShadows.m_Scales[3].xyz + g_Frame.m_SunShadows.m_Offsets[3].xyz;
  r5.yw = v1.xx == float2(1.000000e+000,2.000000e+000);
  r16.x = r15.z;
  r16.yz = float2(2.500000e-001,7.500000e-001);
  r12.w = 7.500000000e-001;
  r16.xyz = r5.www ? r16.xyz : r12.zww;
  r12.xyzw = r5.wwww ? r15.yxxx : r12.yxxx;
  r15.x = r14.z;
  r15.yz = float2(7.500000e-001,2.500000e-001);
  r15.xyz = r5.yyy ? r15.xyz : r16.xyz;
  r12.xyzw = r5.yyyy ? r14.yxxx : r12.xyzw;
  r13.w = 2.500000000e-001;
  r14.xyz = v1.xxx ? r15.xyz : r13.zww;
  r12.xyzw = v1.xxxx ? r12.xyzw : r13.yxxx;
  r12.xyzw = r12.xyzw * float4(2.500000e-001,2.500000e-001,2.500000e-001,2.500000e-001) + r14.zyyy;
  r5.yw = float2(1.000000e+000,1.000000e+000) / g_Frame.m_SunShadows.m_ShadowMapSize.xy;
  r12.xyzw = r12.xyzw / r5.wyyy;
  r12.xyzw = float4(-2.500000e+000,-2.500000e+000,-2.500000e+000,-2.500000e+000) + r12.xyzw;
  r7.zw = floor(r12.wx);
  r12.xyzw = r12.xyzw + -r7.wzzz;
  r5.yw = r7.zw * r5.yw;
  r13.xyz = float3(0.000000e+000,0.000000e+000,0.000000e+000) != g_Frame.m_SunShadows.m_NoiseScale.xyz;
  if (r13.x != 0) {
    r15.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(1,1)).xyzw;
    r16.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(3,1)).xyzw;
    r17.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(5,1)).xyzw;
    r18.xyzw = float4(5.355339e-001,1.535534e+000,1.000000e+000,1.000000e+000) + -r12.wwxw;
    r7.zw = saturate(r18.xy + -r12.xx);
    r0.y = r7.z * r7.z;
    r0.y = r0.y * r15.w;
    r11.zw = min(r7.ww, r18.zw);
    r18.xy = saturate(r18.xy);
    r13.xw = float2(1.000000e+000,1.000000e+000) + -r18.xy;
    r3.z = min(r11.z, r13.x);
    r7.z = -r3.z * 5.000000000e-001 + r11.z;
    r3.z = r7.z * r3.z;
    r3.z = r11.z * r18.x + r3.z;
    r7.z = saturate(5.355339050e-001 + -r12.x);
    r8.w = 1.000000000e+000 + -r7.z;
    r9.w = min(r8.w, r11.w);
    r10.w = -r9.w * 5.000000000e-001 + r11.w;
    r9.w = r10.w * r9.w;
    r9.w = r11.w * r7.z + r9.w;
    r10.w = -r12.x + -r12.w;
    r10.w = saturate(2.535533905e+000 + r10.w);
    r11.z = 1.000000000e+000 + -r7.w;
    r11.z = min(r10.w, r11.z);
    r11.w = -r11.z * 5.000000000e-001 + r10.w;
    r11.z = r11.w * r11.z;
    r7.w = r10.w * r7.w + r11.z;
    r3.z = r15.z * r3.z;
    r0.y = r0.y * 5.000000000e-001 + r3.z;
    r0.y = r15.x * r9.w + r0.y;
    r0.y = r15.y * r7.w + r0.y;
    r3.z = min(r13.w, r18.z);
    r7.w = -r3.z * 5.000000000e-001 + r18.z;
    r3.z = r7.w * r3.z;
    r3.z = r18.z * r18.y + r3.z;
    r7.w = saturate(5.355339050e-001 + r12.w);
    r9.w = 1.000000000e+000 + -r7.w;
    r9.w = min(r9.w, r18.z);
    r10.w = -r9.w * 5.000000000e-001 + r18.z;
    r9.w = r10.w * r9.w;
    r7.w = r18.z * r7.w + r9.w;
    r9.w = r12.w + r12.x;
    r9.w = saturate(-1.535533905e+000 + r9.w);
    r9.w = r9.w * r9.w;
    r9.w = -r9.w * 5.000000000e-001 + 1.000000000e+000;
    r10.w = r18.w + r12.x;
    r10.w = saturate(-1.535533905e+000 + r10.w);
    r10.w = r10.w * r10.w;
    r10.w = -r10.w * 5.000000000e-001 + 1.000000000e+000;
    r0.y = r16.w * r3.z + r0.y;
    r0.y = r16.z * r7.w + r0.y;
    r0.y = r16.x * r9.w + r0.y;
    r0.y = r16.y * r10.w + r0.y;
    r11.zw = float2(5.355339e-001,1.000000e+000) + -r18.ww;
    r3.z = saturate(r11.z + -r12.x);
    r3.z = r3.z * r3.z;
    r3.z = r3.z * r17.z;
    r7.w = -r18.w + -r12.x;
    r13.xw = saturate(float2(1.535534e+000,2.535534e+000) + r7.ww);
    r7.w = min(r13.x, r18.z);
    r11.z = saturate(r11.z);
    r9.w = 1.000000000e+000 + -r11.z;
    r9.w = min(r7.w, r9.w);
    r10.w = -r9.w * 5.000000000e-001 + r7.w;
    r9.w = r10.w * r9.w;
    r7.w = r7.w * r11.z + r9.w;
    r9.w = min(r11.w, r13.x);
    r8.w = min(r8.w, r9.w);
    r10.w = -r8.w * 5.000000000e-001 + r9.w;
    r8.w = r10.w * r8.w;
    r7.z = r9.w * r7.z + r8.w;
    r8.w = 1.000000000e+000 + -r13.x;
    r8.w = min(r8.w, r13.w);
    r9.w = -r8.w * 5.000000000e-001 + r13.w;
    r8.w = r9.w * r8.w;
    r8.w = r13.w * r13.x + r8.w;
    r0.y = r17.w * r7.w + r0.y;
    r0.y = r3.z * 5.000000000e-001 + r0.y;
    r0.y = r17.x * r8.w + r0.y;
    r0.y = r17.y * r7.z + r0.y;
  } else {
    r0.y = 0.000000000e+000;
  }
  if (r13.y != 0) {
    r15.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(1,3)).xyzw;
    r16.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(3,3)).xyzw;
    r17.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(5,3)).xyzw;
    r13.xyw = float3(1.535534e+000,1.000000e+000,1.000000e+000) + -r12.xwx;
    r13.x = saturate(r13.x);
    r3.z = 1.000000000e+000 + -r13.x;
    r7.z = min(r3.z, r13.y);
    r7.w = -r7.z * 5.000000000e-001 + r13.y;
    r7.z = r7.w * r7.z;
    r7.z = r13.y * r13.x + r7.z;
    r7.w = saturate(5.355339050e-001 + r12.x);
    r8.w = 1.000000000e+000 + -r7.w;
    r9.w = min(r8.w, r13.y);
    r10.w = -r9.w * 5.000000000e-001 + r13.y;
    r9.w = r10.w * r9.w;
    r9.w = r13.y * r7.w + r9.w;
    r10.w = r12.x + r12.w;
    r10.w = saturate(-1.535533905e+000 + r10.w);
    r10.w = r10.w * r10.w;
    r10.w = -r10.w * 5.000000000e-001 + 1.000000000e+000;
    r11.zw = r13.wy + r12.wx;
    r11.zw = saturate(float2(-1.535534e+000,-1.535534e+000) + r11.zw);
    r11.zw = r11.zw * r11.zw;
    r11.zw = -r11.zw * float2(5.000000e-001,5.000000e-001) + float2(1.000000e+000,1.000000e+000);
    r7.z = r15.w * r7.z + r0.y;
    r7.z = r15.z * r10.w + r7.z;
    r7.z = r15.x * r9.w + r7.z;
    r7.z = r15.y * r11.z + r7.z;
    r7.z = r7.z + r16.w;
    r7.z = r7.z + r16.z;
    r7.z = r7.z + r16.x;
    r7.z = r7.z + r16.y;
    r9.w = 1.000000000e+000 + -r13.y;
    r3.z = min(r3.z, r9.w);
    r10.w = -r3.z * 5.000000000e-001 + r9.w;
    r3.z = r10.w * r3.z;
    r3.z = r9.w * r13.x + r3.z;
    r8.w = min(r8.w, r9.w);
    r10.w = -r8.w * 5.000000000e-001 + r9.w;
    r8.w = r10.w * r8.w;
    r7.w = r9.w * r7.w + r8.w;
    r8.w = r13.w + r13.y;
    r8.w = saturate(-1.535533905e+000 + r8.w);
    r8.w = r8.w * r8.w;
    r8.w = -r8.w * 5.000000000e-001 + 1.000000000e+000;
    r7.z = r17.w * r11.w + r7.z;
    r3.z = r17.z * r3.z + r7.z;
    r3.z = r17.x * r8.w + r3.z;
    r0.y = r17.y * r7.w + r3.z;
  }
  if (r13.z != 0) {
    r13.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(1,5)).xyzw;
    r15.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(3,5)).xyzw;
    r14.xyzw = t_g_ShadowSampler.GatherCmp(s_LinearCmpWithBorder_s, r5.yw, r14.x, int2(5,5)).xyzw;
    r16.xyzw = float4(5.355339e-001,1.535534e+000,1.000000e+000,1.000000e+000) + -r12.yzxw;
    r5.yw = saturate(r16.xy + -r16.zz);
    r3.z = r5.y * r5.y;
    r3.z = r3.z * r13.x;
    r17.xyzw = float4(1.000000e+000,5.355339e-001,5.355339e-001,1.000000e+000) + -r16.zzww;
    r5.y = min(r5.w, r17.x);
    r16.xy = saturate(r16.xy);
    r7.zw = float2(1.000000e+000,1.000000e+000) + -r16.xy;
    r7.z = min(r5.y, r7.z);
    r8.w = -r7.z * 5.000000000e-001 + r5.y;
    r7.z = r8.w * r7.z;
    r5.y = r5.y * r16.x + r7.z;
    r7.z = min(r5.w, r16.w);
    r11.zw = saturate(r17.yz);
    r12.xy = float2(1.000000e+000,1.000000e+000) + -r11.zw;
    r8.w = min(r7.z, r12.x);
    r9.w = -r8.w * 5.000000000e-001 + r7.z;
    r8.w = r9.w * r8.w;
    r7.z = r7.z * r11.z + r8.w;
    r8.w = -r16.z + -r12.w;
    r8.w = saturate(2.535533905e+000 + r8.w);
    r9.w = 1.000000000e+000 + -r5.w;
    r9.w = min(r8.w, r9.w);
    r10.w = -r9.w * 5.000000000e-001 + r8.w;
    r9.w = r10.w * r9.w;
    r5.w = r8.w * r5.w + r9.w;
    r7.z = r13.w * r7.z + r0.y;
    r5.w = r13.z * r5.w + r7.z;
    r3.z = r3.z * 5.000000000e-001 + r5.w;
    r3.z = r13.y * r5.y + r3.z;
    r5.y = min(r7.w, r17.x);
    r5.w = -r5.y * 5.000000000e-001 + r17.x;
    r5.y = r5.w * r5.y;
    r5.y = r17.x * r16.y + r5.y;
    r5.w = saturate(5.355339050e-001 + r12.w);
    r7.z = 1.000000000e+000 + -r5.w;
    r7.z = min(r7.z, r17.x);
    r7.w = -r7.z * 5.000000000e-001 + r17.x;
    r7.z = r7.w * r7.z;
    r5.w = r17.x * r5.w + r7.z;
    r7.z = r16.z + r12.w;
    r7.z = saturate(-1.535533905e+000 + r7.z);
    r7.z = r7.z * r7.z;
    r7.z = -r7.z * 5.000000000e-001 + 1.000000000e+000;
    r7.w = r16.w + r16.z;
    r7.w = saturate(-1.535533905e+000 + r7.w);
    r7.w = r7.w * r7.w;
    r7.w = -r7.w * 5.000000000e-001 + 1.000000000e+000;
    r3.z = r15.w * r7.z + r3.z;
    r3.z = r15.z * r7.w + r3.z;
    r3.z = r15.x * r5.y + r3.z;
    r3.z = r15.y * r5.w + r3.z;
    r5.y = saturate(r17.z + -r16.z);
    r5.y = r5.y * r5.y;
    r5.y = r5.y * r14.y;
    r5.w = -r16.z + -r16.w;
    r7.zw = saturate(float2(1.535534e+000,2.535534e+000) + r5.ww);
    r12.zw = min(r7.zz, r17.wx);
    r12.xy = min(r12.xy, r12.zw);
    r13.xy = -r12.xy * float2(5.000000e-001,5.000000e-001) + r12.zw;
    r12.xy = r13.xy * r12.xy;
    r11.zw = r12.zw * r11.zw + r12.xy;
    r5.w = 1.000000000e+000 + -r7.z;
    r5.w = min(r5.w, r7.w);
    r8.w = -r5.w * 5.000000000e-001 + r7.w;
    r5.w = r8.w * r5.w;
    r5.w = r7.w * r7.z + r5.w;
    r3.z = r14.w * r5.w + r3.z;
    r3.z = r14.z * r11.z + r3.z;
    r3.z = r14.x * r11.w + r3.z;
    r0.y = r5.y * 5.000000000e-001 + r3.z;
  }
  r0.y = 4.828426987e-002 * r0.y;
  r3.z = dot(r4.xyw, r4.xyw);
  r5.y = 0.000000e+000 != g_VolumeCloudsShadow.UseCloudShadow.x;
  if (r5.y != 0) {
    r12.xyz = r2.xyz * g_VolumeCloudsShadow.CloudScale.xyz + g_VolumeCloudsShadow.CloudTranslate.xyz;
    r5.y = g_VolumeCloudsShadow.CloudProject.z * r12.z;
    r12.xy = g_VolumeCloudsShadow.CloudProject.xy * r5.yy + r12.xy;
    r12.z = g_VolumeCloudsShadow.CloudTranslate.w;
    r5.y = t_g_CloudShadowTexture.SampleLevel(s_TrilinearWrap_s, r12.xyz, g_VolumeCloudsShadow.CloudShadowMipBias.x).y;
    r5.w = saturate(r3.z * g_VolumeCloudsShadow.UseCloudShadow.z + g_VolumeCloudsShadow.UseCloudShadow.w);
    r7.z = 1.000000000e+000 + -g_VolumeCloudsShadow.UseCloudShadow.y;
    r5.w = r5.w * r7.z + g_VolumeCloudsShadow.UseCloudShadow.y;
    r5.y = -1.000000000e+000 + r5.y;
    r5.y = r5.w * r5.y + 1.000000000e+000;
  } else {
    r5.y = 1.000000000e+000;
  }
  r0.y = r5.y * r0.y;
  r5.w = dot(g_DeferredLights.m_DirectLight.m_Direction.xyz, r8.xyz);
  r12.xyz = -r5.www * r8.xyz + g_DeferredLights.m_DirectLight.m_Direction.xyz;
  r5.w = dot(r12.xyz, r12.xyz);
  r5.w = rsqrt(r5.w);
  r12.xyz = r12.xyz * r5.www;
  r12.xyz = r0.www ? r12.xyz : r6.xyz;
  r3.z = rsqrt(r3.z);
  r13.xyz = r4.xyw * r3.zzz;
  r4.xyw = r4.xyw * r3.zzz + g_DeferredLights.m_DirectLight.m_Direction.xyz;
  r3.z = dot(r4.xyw, r4.xyw);
  r3.z = rsqrt(r3.z);
  r4.xyw = r4.xyw * r3.zzz;
  r3.z = dot(r12.xyz, g_DeferredLights.m_DirectLight.m_Direction.xyz);
  r7.x = saturate(dot(r12.xyz, r13.xyz));
  r5.w = dot(r12.xyz, r4.xyw);
  r11.x = r3.z * 5.000000000e-001 + 5.000000000e-001;
  r7.zw = r11.xy * float2(9.687500e-001,9.687500e-001) + float2(1.562500e-002,1.562500e-002);
  r7.z = t_BRDFLUT.SampleLevel(s_TrilinearClamp_s, r7.zw, 0.000000000e+000).z;
  r7.w = saturate(-r3.z);
  r5.z = r7.w * r5.z;
  r11.xyz = g_DeferredLights.m_DirectLight.m_Color.xyz * r0.yyy;
  r14.xyz = r11.xyz * r7.zzz;
  r11.xyz = r5.zzz * r11.xyz + r14.xyz;
  r11.xyz = r11.xyz * r1.www;
  r0.y = dot(r14.xyz, float3(2.126000e-001,7.152000e-001,7.220000e-002));
  if (r0.w != 0) {
    r7.zw = float2(1.000000e+000,1.000000e+000) + r3.xy;
    r7.zw = sqrt(r7.zw);
    r7.zw = float2(1.250000e-001,1.250000e-001) * r7.zw;
    r5.z = dot(r4.xyw, r8.xyz);
    r5.z = r5.z * r5.z;
    r3.xy = r5.zz * r3.xy;
    r5.z = 1.000000000e+000 + r5.w;
    r3.xy = -r3.xy / r5.zz;
    r3.xy = float2(1.442695e+000,1.442695e+000) * r3.xy;
    r3.xy = exp2(r3.xy);
    r3.xy = r7.zw * r3.xy;
    r8.xyz = r3.xxx * r10.xyz;
    r3.x = r3.y * r4.z;
    r8.xyz = r8.xyz * r1.xyz + r3.xxx;
    r8.xyz = r8.xyz * r14.xyz;
  } else {
    r3.z = saturate(r3.z);
    r5.w = saturate(r5.w);
    r3.x = saturate(dot(r13.xyz, r4.xyw));
    r3.y = -1.000000000e+000 + r7.y;
    r4.x = r5.w * r5.w;
    r3.y = r4.x * r3.y + 1.000000000e+000;
    r3.y = r3.y * r3.y;
    r3.y = r7.y / r3.y;
    r4.yzw = float3(1.000000e+000,1.000000e+000,1.000000e+000) + -r10.xyz;
    r3.x = 1.000000000e+000 + -r3.x;
    r5.z = r3.x * r3.x;
    r5.z = r5.z * r5.z;
    r3.x = r5.z * r3.x;
    r4.yzw = r4.yzw * r3.xxx + r10.xyz;
    r3.x = 1.000000000e+000 + -r7.y;
    r5.z = r3.z * r3.x + r7.y;
    r5.z = sqrt(r5.z);
    r3.z = r5.z + r3.z;
    r3.z = 1.000000e+000 / r3.z;
    r3.x = r7.x * r3.x + r7.y;
    r3.x = sqrt(r3.x);
    r3.x = r7.x + r3.x;
    r3.x = 1.000000e+000 / r3.x;
    r3.x = r3.z * r3.x;
    r3.z = r3.y * r3.x;
    r5.z = 0.000000000e+000 < r5.x;
    r5.w = -r5.w * r5.w + 1.000100017e+000;
    r7.z = r5.w * r5.w;
    r4.x = r4.x / r5.w;
    r4.x = -r4.x / r7.y;
    r4.x = 1.442695022e+000 * r4.x;
    r4.x = exp2(r4.x);
    r4.x = 4.000000000e+000 * r4.x;
    r4.x = r4.x / r7.z;
    r4.x = 1.000000000e+000 + r4.x;
    r5.w = r7.y * 4.000000000e+000 + 1.000000000e+000;
    r4.x = r4.x / r5.w;
    r3.x = -r3.y * r3.x + r4.x;
    r3.x = r5.x * r3.x + r3.z;
    r3.x = r5.z ? r3.x : r3.z;
    r4.xyz = r4.yzw * r0.zzz;
    r4.xyz = r4.xyz * r0.xxx;
    r3.xyz = r4.xyz * r3.xxx;
    r8.xyz = r14.xyz * r3.xyz;
  }
  r3.x = 0.000000e+000 != g_DeferredLights.m_IsolateVars.x;
  if (r3.x != 0) {
    r3.x = dot(-r13.xyz, r12.xyz);
    r3.x = r3.x + r3.x;
    r4.xyz = r12.xyz * -r3.xxx + -r13.xyz;
    r3.xyz = g_Frame.m_GIConsts.Params.yyy * r6.xyz;
    r12.xyz = r3.xyz * float3(5.000000e-001,5.000000e-001,5.000000e-001) + r2.xyz;
    r3.xyz = r12.xyz * g_Frame.m_GIConsts.WSToIndirectionScale.xyz + g_Frame.m_GIConsts.WSToIndirectionBias.xyz;
    r13.xyz = (uint3)r3.xyz;
    r13.w = 0.000000000e+000;
    r3.x = g_WorldGIIndirection.Load(r13.xyzw).x;
    if (r3.x != 0) {
      r13.xy = (uint2)v0.xy;
      r13.zw = float2(0.000000e+000,0.000000e+000);
      r3.y = g_VolumeIndex.Load(r13.xyz).x;
      r3.z = (int)r3.x + -1;
// Known bad code for instruction (needs manual fix):
//     ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r13.xyzw, r3.z, l(0), t28.xyzw
r13.x = g_WorldGICells[r3.z].WSToUnitScale.x;
r13.y = g_WorldGICells[r3.z].WSToUnitScale.y;
r13.z = g_WorldGICells[r3.z].WSToUnitScale.z;
r13.w = g_WorldGICells[r3.z].WSToUnitBias.x;
// Known bad code for instruction (needs manual fix):
//     ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r14.xyzw, r3.z, l(16), t28.zwxy
r14.x = g_WorldGICells[r3.z].WSToUnitBias.y;
r14.y = g_WorldGICells[r3.z].WSToUnitBias.z;
r14.z = g_WorldGICells[r3.z].UnitToVolumeScale.x;
r14.w = g_WorldGICells[r3.z].UnitToVolumeScale.y;
// Known bad code for instruction (needs manual fix):
//     ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r15.xyzw, r3.z, l(32), t28.xyzw
r15.x = g_WorldGICells[r3.z].UnitToVolumeScale.z;
r15.y = g_WorldGICells[r3.z].UnitToVolumeBias.x;
r15.z = g_WorldGICells[r3.z].UnitToVolumeBias.y;
r15.w = g_WorldGICells[r3.z].UnitToVolumeBias.z;
// Known bad code for instruction (needs manual fix):
//     ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r3.z, r3.z, l(48), t28.xxxx
r3.z = g_WorldGICells[r3.z].NormalBiasScale.x;
      r16.x = r13.w;
      r16.yz = r14.zw;
      r13.xyz = r12.xyz * r13.xyz + r16.xyz;
      r16.xyz = r6.xyz * r3.zzz;
      r13.xyz = saturate(r16.xyz * g_Frame.m_GIConsts.Params.yyy + r13.xyz);
      r14.z = r15.x;
      r13.xyz = r13.xyz * r14.xyz + r15.yzw;
      r14.xyzw = t_g_WorldGIVolume0.SampleLevel(s_g_WorldGIVolumeSampler_s, r13.xyz, 0.000000000e+000).xyzw;
      r15.xyzw = t_g_WorldGIVolume1.SampleLevel(s_g_WorldGIVolumeSampler_s, r13.xyz, 0.000000000e+000).xyzw;
      r16.xyzw = t_g_WorldGIVolume2.SampleLevel(s_g_WorldGIVolumeSampler_s, r13.xyz, 0.000000000e+000).xyzw;
      r13.xyzw = t_g_WorldGIVolume3.SampleLevel(s_g_WorldGIVolumeSampler_s, r13.xyz, 0.000000000e+000).xyzw;
      r3.z = (int)r3.y & 0x0000ffff;
      if (r3.z != 0) {
        r3.z = (int)r3.y & 255;
        r3.z = (int)r3.z + -1;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r17.xyzw, r3.z, l(0), t26.xyzw
r17.x = g_IndoorGIVolumes[r3.z]._m00;
r17.y = g_IndoorGIVolumes[r3.z]._m01;
r17.z = g_IndoorGIVolumes[r3.z]._m02;
r17.w = g_IndoorGIVolumes[r3.z]._m03;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r18.xyzw, r3.z, l(16), t26.xyzw
r18.x = g_IndoorGIVolumes[r3.z]._m10;
r18.y = g_IndoorGIVolumes[r3.z]._m11;
r18.z = g_IndoorGIVolumes[r3.z]._m12;
r18.w = g_IndoorGIVolumes[r3.z]._m13;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r19.xyzw, r3.z, l(32), t26.xyzw
r19.x = g_IndoorGIVolumes[r3.z]._m20;
r19.y = g_IndoorGIVolumes[r3.z]._m21;
r19.z = g_IndoorGIVolumes[r3.z]._m22;
r19.w = g_IndoorGIVolumes[r3.z]._m23;
        r12.w = 1.000000000e+000;
        r17.x = dot(r12.xyzw, r17.xyzw);
        r17.y = dot(r12.xyzw, r18.xyzw);
        r17.z = dot(r12.xyzw, r19.xyzw);
        if (8 == 0) r3.z = 0; else if (8+8 < 32) {         r3.z = (int)r3.y << (32-(8 + 8)); r3.z = (uint)r3.z >> (32-8);        } else r3.z = (uint)r3.y >> 8;
        r3.z = r3.z;
        r3.z = 3.921568859e-003 * r3.z;
        r18.xyzw = t_g_WorldGIVolume0.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r19.xyzw = t_g_WorldGIVolume1.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r20.xyzw = t_g_WorldGIVolume2.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r17.xyzw = t_g_WorldGIVolume3.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r18.xyzw = r18.xyzw + -r14.xyzw;
        r14.xyzw = r3.zzzz * r18.xyzw + r14.xyzw;
        r18.xyzw = r19.xyzw + -r15.xyzw;
        r15.xyzw = r3.zzzz * r18.xyzw + r15.xyzw;
        r18.xyzw = r20.xyzw + -r16.xyzw;
        r16.xyzw = r3.zzzz * r18.xyzw + r16.xyzw;
        r17.xyzw = r17.xyzw + -r13.xyzw;
        r13.xyzw = r3.zzzz * r17.xyzw + r13.xyzw;
      } else {
        r3.z = 0.000000000e+000;
      }
      r5.z = (uint)r3.y >> 16;
      if (r5.z != 0) {
        if (8 == 0) r3.y = 0; else if (8+16 < 32) {         r3.y = (int)r3.y << (32-(8 + 16)); r3.y = (uint)r3.y >> (32-8);        } else r3.y = (uint)r3.y >> 16;
        r3.y = (int)r3.y + -1;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r17.xyzw, r3.y, l(0), t26.xyzw
r17.x = g_IndoorGIVolumes[r3.y]._m00;
r17.y = g_IndoorGIVolumes[r3.y]._m01;
r17.z = g_IndoorGIVolumes[r3.y]._m02;
r17.w = g_IndoorGIVolumes[r3.y]._m03;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r18.xyzw, r3.y, l(16), t26.xyzw
r18.x = g_IndoorGIVolumes[r3.y]._m10;
r18.y = g_IndoorGIVolumes[r3.y]._m11;
r18.z = g_IndoorGIVolumes[r3.y]._m12;
r18.w = g_IndoorGIVolumes[r3.y]._m13;
// Known bad code for instruction (needs manual fix):
//       ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r19.xyzw, r3.y, l(32), t26.xyzw
r19.x = g_IndoorGIVolumes[r3.y]._m20;
r19.y = g_IndoorGIVolumes[r3.y]._m21;
r19.z = g_IndoorGIVolumes[r3.y]._m22;
r19.w = g_IndoorGIVolumes[r3.y]._m23;
        r12.w = 1.000000000e+000;
        r17.x = dot(r12.xyzw, r17.xyzw);
        r17.y = dot(r12.xyzw, r18.xyzw);
        r17.z = dot(r12.xyzw, r19.xyzw);
        r3.y = (uint)r5.z >> 8;
        r3.y = r3.y;
        r3.y = 3.921568859e-003 * r3.y;
        r12.xyzw = t_g_WorldGIVolume0.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r18.xyzw = t_g_WorldGIVolume1.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r19.xyzw = t_g_WorldGIVolume2.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r17.xyzw = t_g_WorldGIVolume3.SampleLevel(s_g_WorldGIVolumeSampler_s, r17.xyz, 0.000000000e+000).xyzw;
        r3.z = 1.000000000e+000 + -r3.z;
        r3.y = min(r3.z, r3.y);
        r12.xyzw = r12.xyzw + -r14.xyzw;
        r14.xyzw = r3.yyyy * r12.xyzw + r14.xyzw;
        r12.xyzw = r18.xyzw + -r15.xyzw;
        r15.xyzw = r3.yyyy * r12.xyzw + r15.xyzw;
        r12.xyzw = r19.xyzw + -r16.xyzw;
        r16.xyzw = r3.yyyy * r12.xyzw + r16.xyzw;
        r12.xyzw = r17.xyzw + -r13.xyzw;
        r13.xyzw = r3.yyyy * r12.xyzw + r13.xyzw;
      }
      r3.y = g_Pass.m_GlobalLightingScale.y * r5.y;
      r12.xyzw = r14.xyzw * r3.yyyy;
      r14.xyzw = r15.xyzw * r3.yyyy;
      r15.xyzw = r16.xyzw * r3.yyyy;
      r6.w = 1.000000000e+000;
      r16.x = dot(r12.xyzw, r6.xyzw);
      r16.y = dot(r14.xyzw, r6.xyzw);
      r16.z = dot(r15.xyzw, r6.xyzw);
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r17.xyzw, l(0), l(0), t56.xyzw
r17.x = g_SkySHConstants[0].Values[0].x;
r17.y = g_SkySHConstants[0].Values[0].y;
r17.z = g_SkySHConstants[0].Values[0].z;
r17.w = g_SkySHConstants[0].Values[0].w;
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r18.xyzw, l(0), l(16), t56.xyzw
r18.x = g_SkySHConstants[0].Values[1].x;
r18.y = g_SkySHConstants[0].Values[1].y;
r18.z = g_SkySHConstants[0].Values[1].z;
r18.w = g_SkySHConstants[0].Values[1].w;
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r19.xyzw, l(0), l(32), t56.xyzw
r19.x = g_SkySHConstants[0].Values[2].x;
r19.y = g_SkySHConstants[0].Values[2].y;
r19.z = g_SkySHConstants[0].Values[2].z;
r19.w = g_SkySHConstants[0].Values[2].w;
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r20.xyzw, l(0), l(48), t56.xyzw
r20.x = g_SkySHConstants[0].Values[3].x;
r20.y = g_SkySHConstants[0].Values[3].y;
r20.z = g_SkySHConstants[0].Values[3].z;
r20.w = g_SkySHConstants[0].Values[3].w;
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r21.xyzw, l(0), l(64), t56.xyzw
r21.x = g_SkySHConstants[0].Values[4].x;
r21.y = g_SkySHConstants[0].Values[4].y;
r21.z = g_SkySHConstants[0].Values[4].z;
r21.w = g_SkySHConstants[0].Values[4].w;
// // Known bad code for instruction (needs manual fix):
// //     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r22.xyzw, l(0), l(80), t56.xyzw
r22.x = g_SkySHConstants[0].Values[5].x;
r22.y = g_SkySHConstants[0].Values[5].y;
r22.z = g_SkySHConstants[0].Values[5].z;
r22.w = g_SkySHConstants[0].Values[5].w;
// Known bad code for instruction (needs manual fix):
//     ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r5.yzw, l(0), l(96), t56.xxyz
r5.y = g_SkySHConstants[0].Values[6].x;
r5.z = g_SkySHConstants[0].Values[6].y;
r5.w = g_SkySHConstants[0].Values[6].z;
      r23.x = dot(r17.xyzw, r6.xyzw);
      r23.y = dot(r18.xyzw, r6.xyzw);
      r23.z = dot(r19.xyzw, r6.xyzw);
      r24.xyzw = r6.xyzx * r6.yzzz;
      r20.x = dot(r20.xyzw, r24.xyzw);
      r20.y = dot(r21.xyzw, r24.xyzw);
      r20.z = dot(r22.xyzw, r24.xyzw);
      r3.y = r6.y * r6.y;
      r3.y = r6.x * r6.x + -r3.y;
      r20.xyz = r23.xyz + r20.xyz;
      r5.yzw = r5.yzw * r3.yyy + r20.xyz;
      r5.yzw = max(r5.yzw, float3(0.000000e+000,0.000000e+000,0.000000e+000));
      r3.y = dot(r13.xyzw, r6.xyzw);
      r5.yzw = r5.yzw * r3.yyy + r16.xyz;
      r4.w = 1.000000000e+000;
      r3.y = dot(r13.xyzw, r4.xyzw);
      r12.x = dot(r12.xyzw, r4.xyzw);
      r12.y = dot(r14.xyzw, r4.xyzw);
      r12.z = dot(r15.xyzw, r4.xyzw);
      r13.x = dot(r17.xyzw, r4.xyzw);
      r13.y = dot(r18.xyzw, r4.xyzw);
      r13.z = dot(r19.xyzw, r4.xyzw);
      r13.xyz = max(r13.xyz, float3(0.000000e+000,0.000000e+000,0.000000e+000));
      r12.xyz = r13.xyz * r3.yyy + r12.xyz;
      r3.z = dot(r12.xyz, float3(2.126000e-001,7.152000e-001,7.220000e-002));
    } else {
      r5.yzw = float3(0.000000e+000,0.000000e+000,0.000000e+000);
      r3.yz = float2(1.000000e+000,1.000000e+000);
    }
    r6.w = 0.000000e+000 != g_Frame.m_GIConsts.Params.x;
    r6.w = ~(int)r6.w;
    r3.x = r3.x == 0;
    r3.x = (int)r3.x | (int)r6.w;
    if (r3.x != 0) {
      r5.yzw = t_g_SkyLightingCubeTexture.SampleLevel(s_TrilinearClamp_s, r6.xyz, 0.000000000e+000).xyz;
      r3.z = dot(r5.yzw, float3(2.126000e-001,7.152000e-001,7.220000e-002));
      r3.y = r6.z * 5.000000000e-001 + 5.000000000e-001;
    }
    r5.yzw = r5.yzw * r0.xxx;
    r0.x = r0.z * r0.x;
    r3.x = dot(r5.yzw, float3(2.126000e-001,7.152000e-001,7.220000e-002));
    r3.w = -r3.w * 6.333333492e+000 + 6.333333492e+000;
    r6.xy = (int2)v1.yz * int2(10,10);
    
// Manual fix, wrong array indexing in this complicated array of structs
// dp4 r12.x, r2.xyzw, cb1[r6.x + 53].xyzw
// dp4 r12.y, r2.xyzw, cb1[r6.x + 54].xyzw
// dp4 r12.z, r2.xyzw, cb1[r6.x + 55].xyzw
// dp4 r13.x, r2.xyzw, cb1[r6.y + 53].xyzw
// dp4 r13.y, r2.xyzw, cb1[r6.y + 54].xyzw
// dp4 r13.z, r2.xyzw, cb1[r6.y + 55].xyzw
r12.x = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m00_m10_m20_m30);
r12.y = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m01_m11_m21_m31);
r12.z = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m02_m12_m22_m32);
r13.x = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m00_m10_m20_m30);
r13.y = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m01_m11_m21_m31);
r13.z = dot(r2.xyzw, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m02_m12_m22_m32);

// add r14.xyz, |r12.xyzx|, -cb1[r6.x + 50].xyzx
// add r15.xyz, -cb1[r6.x + 50].xyzx, cb1[r6.x + 51].xyzx
r14.xyz = -g_Frame.m_LocalCubeMaps[r6.x].innerBlendBoxMax.xyz + abs(r12.xyz);
r15.xyz = g_Frame.m_LocalCubeMaps[r6.x].innerBlendBoxMax.xyz + -g_Frame.m_LocalCubeMaps[r6.x].blendBoxMax.xyz;

    r14.xyz = r14.xyz / r15.xyz;
    
// add r15.xyz, |r13.xyzx|, -cb1[r6.y + 50].xyzx
// add r16.xyz, -cb1[r6.y + 50].xyzx, cb1[r6.y + 51].xyzx
r15.xyz = -g_Frame.m_LocalCubeMaps[r6.y].innerBlendBoxMax.xyz + abs(r13.xyz);
r16.xyz = g_Frame.m_LocalCubeMaps[r6.y].innerBlendBoxMax.xyz + -g_Frame.m_LocalCubeMaps[r6.y].blendBoxMax.xyz;
    
    r15.xyz = r15.xyz / r16.xyz;
    r16.xyz = r14.xyz < float3(0.000000e+000,0.000000e+000,0.000000e+000);
    r2.w = r16.y ? r16.x : 0;
    r2.w = r16.z ? r2.w : 0;
    r16.xyz = r15.xyz < float3(0.000000e+000,0.000000e+000,0.000000e+000);
    r6.z = r16.y ? r16.x : 0;
    r6.z = r16.z ? r6.z : 0;
    r14.xyz = saturate(r14.xyz);
    r6.w = max(r14.y, r14.x);
    r6.w = max(r14.z, r6.w);
    r7.z = 9.999999747e-005 + r6.w;
    r14.xy = float2(1.000000e+000,1.000100e+000) + -r6.ww;
    r15.xyz = saturate(r15.xyz);
    r7.w = max(r15.y, r15.x);
    r7.w = max(r15.z, r7.w);
    r7.z = r7.z + r7.w;
    r8.w = 1.000000000e+000 + -r7.w;
    r9.w = r14.y + r8.w;
    r6.w = r6.w / r7.z;
    r6.w = 1.000000000e+000 + -r6.w;
    r10.w = r14.x / r9.w;
    r11.w = r10.w * r6.w;
    r7.z = r7.w / r7.z;
    r7.z = 1.000000000e+000 + -r7.z;
    r7.w = r8.w / r9.w;
    r7.z = r7.z * r7.w;
    r6.w = r6.w * r10.w + r7.z;
    r7.w = r6.w == 0.000000;
    r6.w = 1.000000e+000 / r6.w;
    r6.w = r7.w ? 1.000000000e+000 : r6.w;
    r14.y = r11.w * r6.w;
    r14.z = r7.z * r6.w;
    r6.w = min(r9.w, 8.999999762e-001);
    r14.x = 1.111111164e+000 * r6.w;
    r14.xyz = r6.zzz ? float3(1.000000e+000,0.000000e+000,1.000000e+000) : r14.xyz;
    r14.xyz = r2.www ? float3(1.000000e+000,1.000000e+000,0.000000e+000) : r14.xyz;

// ld_indexable(buffer)(float,float,float,float) r15.xyzw, v1.yyyy, t48.xyzw
r15.xyzw = g_GILocalCubeMapsSRV.Load(v1.y).xyzw;
    
    r4.w = 1.000000000e+000;
    r2.w = saturate(dot(r15.xyzw, r4.xyzw));
    r2.w = saturate(r3.z / r2.w);

// ld_indexable(buffer)(float,float,float,float) r15.xyzw, v1.zzzz, t48.xyzw
r15.xyzw = g_GILocalCubeMapsSRV.Load(v1.z).xyzw;

    r4.w = saturate(dot(r15.xyzw, r4.xyzw));
    r3.z = saturate(r3.z / r4.w);
    r2.w = r14.y * r2.w;
    
// dp3 r15.x, r4.xyzx, cb1[r6.x + 53].xyzx
// dp3 r15.y, r4.xyzx, cb1[r6.x + 54].xyzx
// dp3 r15.z, r4.xyzx, cb1[r6.x + 55].xyzx
r15.x = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m00_m10_m20);
r15.y = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m01_m11_m21);
r15.z = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m02_m12_m22);

// add r16.xyz, -r12.xyzx, cb1[r6.x + 48].xyzx
r16.xyz = g_Frame.m_LocalCubeMaps[r6.x].boxMax.xyz + -r12.xyz;

    r16.xyz = r16.xyz / r15.xyz;
    
// add r12.xyz, -r12.xyzx, cb1[r6.x + 49].xyzx
r12.xyz = g_Frame.m_LocalCubeMaps[r6.x].boxMin.xyz + -r12.xyz;

    r12.xyz = r12.xyz / r15.xyz;
    r12.xyz = max(r12.xyz, r16.xyz);
    r4.w = min(r12.y, r12.x);
    r4.w = min(r12.z, r4.w);
    r12.xyz = r4.xyz * r4.www + r2.xyz;
    
// add r12.xyz, r12.xyzx, -cb1[r6.x + 52].xyzx
r12.xyz = -g_Frame.m_LocalCubeMaps[r6.x].worldPosition.xyz + r12.xyz;
  
// dp3 r15.x, r12.xyzx, cb1[r6.x + 53].xyzx
// dp3 r15.y, r12.xyzx, cb1[r6.x + 54].xyzx
// dp3 r15.z, r12.xyzx, cb1[r6.x + 55].xyzx
r15.x = dot(r12.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m00_m10_m20);
r15.y = dot(r12.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m01_m11_m21);
r15.z = dot(r12.xyz, g_Frame.m_LocalCubeMaps[r6.x].worldToLocal._m02_m12_m22);
    
// utof r15.w, cb1[r6.x + 57].x
r15.w = g_Frame.m_LocalCubeMaps[r6.x].cubeMapArrayIndex;
    
    r6.xzw = t_LocalCubeMaps.SampleLevel(s_LocalCubeMaps_s, r15.xyzw, r3.w).xyz;
    r3.z = r14.z * r3.z;
  
// dp3 r12.x, r4.xyzx, cb1[r6.y + 53].xyzx
// dp3 r12.y, r4.xyzx, cb1[r6.y + 54].xyzx
// dp3 r12.z, r4.xyzx, cb1[r6.y + 55].xyzx
r12.x = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m00_m10_m20);
r12.y = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m01_m11_m21);
r12.z = dot(r4.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m02_m12_m22);
  
// add r14.yzw, -r13.xxyz, cb1[r6.y + 48].xxyz
r14.yzw = g_Frame.m_LocalCubeMaps[r6.y].boxMax.xyz + -r13.xyz;
  
  r14.yzw = r14.yzw / r12.xyz;

// add r13.xyz, -r13.xyzx, cb1[r6.y + 49].xyzx
r13.xyz = g_Frame.m_LocalCubeMaps[r6.y].boxMin.xyz + -r13.xyz;

    r12.xyz = r13.xyz / r12.xyz;
    r12.xyz = max(r12.xyz, r14.yzw);
    r4.w = min(r12.y, r12.x);
    r4.w = min(r12.z, r4.w);
    r2.xyz = r4.xyz * r4.www + r2.xyz;

// add r2.xyz, r2.xyzx, -cb1[r6.y + 52].xyzx
r2.xyz = -g_Frame.m_LocalCubeMaps[r6.y].worldPosition.xyz + r2.xyz;

// dp3 r12.x, r2.xyzx, cb1[r6.y + 53].xyzx
// dp3 r12.y, r2.xyzx, cb1[r6.y + 54].xyzx
// dp3 r12.z, r2.xyzx, cb1[r6.y + 55].xyzx
r12.x = dot(r2.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m00_m10_m20);
r12.y = dot(r2.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m01_m11_m21);
r12.z = dot(r2.xyz, g_Frame.m_LocalCubeMaps[r6.y].worldToLocal._m02_m12_m22);

// utof r12.w, cb1[r6.y + 57].x
r12.w = g_Frame.m_LocalCubeMaps[r6.y].cubeMapArrayIndex;

    r2.xyz = t_LocalCubeMaps.SampleLevel(s_LocalCubeMaps_s, r12.xyzw, r3.w).xyz;
    r2.xyz = r3.zzz * r2.xyz;
    r2.xyz = r2.www * r6.xzw + r2.xyz;
    r4.xyz = t_GlobalEnvMap.SampleLevel(s_LocalCubeMaps_s, r4.xyz, r3.w).xyz;
    r3.yzw = r4.xyz * r3.yyy;
    r2.w = 1.000000000e+000 + -r14.x;
    r2.xyz = r14.xxx * r2.xyz;
    r2.xyz = r2.www * r3.yzw + r2.xyz;
    r2.w = dot(r2.xyz, g_Frame.m_LocalCubeMapParams[1].xyz);
    r2.xyz = r2.xyz * g_Frame.m_LocalCubeMapParams[0].zzz + r2.www;
    r2.w = g_Frame.m_LocalCubeMapParams[0].w * g_Frame.m_LocalCubeMapParams[0].y + r2.z;
    r2.xyz = g_Pass.m_GlobalLightingScale.yyy * r2.xyw;
    r3.yzw = r7.xyy * float3(9.687500e-001,9.687500e-001,4.000000e+000) + float3(1.562500e-002,1.562500e-002,1.000000e+000);
    r3.yz = t_BRDFLUT.SampleLevel(s_TrilinearClamp_s, r3.yz, 0.000000000e+000).xy;
    r4.xyz = r3.zzz * r10.xyz + r3.yyy;
    r6.xyz = r4.xyz * r0.xxx;
    r1.xyz = r6.xyz * r1.xyz;
    r1.xyz = r0.www ? r1.xyz : r6.xyz;
    r1.xyz = r2.xyz * r1.xyz;
    r0.x = 0.000000000e+000 < r5.x;
    r0.w = r7.x * r7.x;
    r2.x = -r7.x * r7.x + 1.000100017e+000;
    r2.y = r2.x * r2.x;
    r0.w = r0.w / r2.x;
    r0.w = -r0.w / r7.y;
    r0.w = 1.442695022e+000 * r0.w;
    r0.w = exp2(r0.w);
    r0.w = 4.000000000e+000 * r0.w;
    r0.w = r0.w / r2.y;
    r0.w = 1.000000000e+000 + r0.w;
    r0.w = r0.w / r3.w;
    r2.xyz = r0.www * r4.xyz;
    r2.xyz = r2.xyz * r0.zzz;
    r2.xyz = r2.xyz * r5.yzw;
    r2.xyz = r2.xyz * r5.xxx + -r1.xyz;
    r2.xyz = r5.xxx * r2.xyz + r1.xyz;
    r0.xzw = r0.xxx ? r2.xyz : r1.xyz;
    r11.xyz = r5.yzw * r1.www + r11.xyz;
    r1.x = r3.x + r0.y;
    r0.xzw = g_DeferredLights.m_EnvironmentSpecularScale * r0.xzw + r8.xyz;
    r8.xyz = r0.xzw + r9.xyz;
    r0.x = dot(r9.xyz, float3(2.126000e-001,7.152000e-001,7.220000e-002));
    r0.y = r1.x + r0.x;
  }
  o0.xyz = g_Pass.m_GlobalLightingScale.xxx * r11.xyz;
  o1.xyz = g_Pass.m_GlobalLightingScale.xxx * r8.xyz;
  o0.w = g_Pass.m_GlobalLightingScale.x * r0.y;
  o1.w = 1.000000000e+000;
  return;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Generated by Microsoft (R) HLSL Shader Compiler 9.29.952.3111
//
//
// Buffer Definitions: 
//
// cbuffer cb_g_Frame
// {
//
//   struct FrameConsts
//   {
//       
//       float4 m_CurrentTime;          // Offset:    0
//       bool m_DeconstructionEnabled;  // Offset:   16
//       float4 m_DeconstructionRanges; // Offset:   32
//       float4 m_DeconstructionOrigin; // Offset:   48
//       float4 m_GlobalWind;           // Offset:   64
//       float4 m_WeatherInfo;          // Offset:   80
//       float4 m_SkyVisibilityWetnessBias;// Offset:   96
//       float4 m_MainPlayerPosition;   // Offset:  112
//       
//       struct SunShadowConsts
//       {
//           
//           float4 m_ShadowMapSize;    // Offset:  128
//           float4 m_Offsets[4];       // Offset:  144
//           float4 m_Scales[4];        // Offset:  208
//           float4 m_SplitBlendMulAddUVAndZ[4];// Offset:  272
//           float4 m_NoiseScale;       // Offset:  336
//           float4 m_NearFar;          // Offset:  352
//           float4 m_FadeParams;       // Offset:  368
//           float4 m_CascadesRangesMax;// Offset:  384
//           float4 m_CascadesRangesMin;// Offset:  400
//           float4 m_ShadowSplitBlendUVAmount;// Offset:  416
//           float4x4 m_WorldToLightProj;// Offset:  432
//           float4x4 m_FarWorldToLightProj;// Offset:  496
//           float4x4 m_DebugShadowVisiblePixelMat;// Offset:  560
//
//       } m_SunShadows;                // Offset:  128
//       
//       struct DirectLightConsts
//       {
//           
//           float4 m_Direction;        // Offset:  624
//           float4 m_Color;            // Offset:  640
//
//       } m_SunLight;                  // Offset:  624
//       
//       struct GISamplingConfig
//       {
//           
//           float4 Params;             // Offset:  656
//           float4 WSToIndirectionScale;// Offset:  672
//           float4 WSToIndirectionBias;// Offset:  688
//           float4 InvVolumeSize;      // Offset:  704
//           float4 InvVolumeAtlasSize; // Offset:  720
//
//       } m_GIConsts;                  // Offset:  656
//       float4 m_LocalCubeMapParams[2];// Offset:  736
//       
//       struct LocalCubeMapParams
//       {
//           
//           float4 boxMax;             // Offset:  768
//           float4 boxMin;             // Offset:  784
//           float4 innerBlendBoxMax;   // Offset:  800
//           float4 blendBoxMax;        // Offset:  816
//           float4 worldPosition;      // Offset:  832
//           float4x4 worldToLocal;     // Offset:  848
//           uint cubeMapArrayIndex;    // Offset:  912
//           float padding;             // Offset:  916
//
//       } m_LocalCubeMaps[32];         // Offset:  768
//       
//       struct VolumetricFogConsts
//       {
//           
//           float4 VolumeInvTransZ;    // Offset: 5888
//           float4 VolumeTexScale;     // Offset: 5904
//           float4 VolumeTexBias;      // Offset: 5920
//           float4 SunColor;           // Offset: 5936
//           float4 SunColorByOneOverPi;// Offset: 5952
//
//       } m_VolumetricFog;             // Offset: 5888
//       
//       struct SurfaceWeatherModificationConsts
//       {
//           
//           float RippleScale;         // Offset: 5968
//           float2 SurfaceFloodLevelRef;// Offset: 5972
//           float4 RippleImpactSurfaceSizeInvSize;// Offset: 5984
//
//       } m_SurfaceWeatherModifications;// Offset: 5968
//       
//       struct RainBlockerConsts
//       {
//           
//           float4 HeightMapSize;      // Offset: 6000
//           float4 HeightMapOffset;    // Offset: 6016
//
//       } m_RainBlockerConsts;         // Offset: 6000
//       float4 m_WorldMapFogExtents;   // Offset: 6032
//       float4 m_WorldMapFogTextureSize;// Offset: 6048
//       float m_WorldMapFogMinHeight;  // Offset: 6064
//       float m_WorldMapFogMaxHeight;  // Offset: 6068
//       uint m_WorldMapFogVisibilityFlags;// Offset: 6072
//       float4 m_WorldMapDistrictColors[32];// Offset: 6080
//       float4 m_UILighting[6];        // Offset: 6592
//       float m_CharacterEffectMultiplier;// Offset: 6688
//
//   } g_Frame;                         // Offset:    0 Size:  6692
//
// }
//
// cbuffer cb_g_Pass
// {
//
//   struct PassConsts
//   {
//       
//       float4 m_EyePosition;          // Offset:    0
//       float4 m_EyeDirection;         // Offset:   16
//       float4x4 m_ViewToWorld;        // Offset:   32
//       float4x4 m_WorldToView;        // Offset:   96
//       float4x4 m_ProjMatrix;         // Offset:  160
//       float4x4 m_ViewProj;           // Offset:  224
//       float4x4 m_ViewNoTranslationProj;// Offset:  288
//       float4 m_ViewTranslation;      // Offset:  352
//       
//       struct ReverseProjParams
//       {
//           
//           float4x4 clipXYZToViewPos; // Offset:  368
//           float4x4 clipXYZToWorldPos;// Offset:  432
//           float4 clipZToViewZ;       // Offset:  496
//
//       } reverseProjParams;           // Offset:  368
//       float4 m_VPosToUV;             // Offset:  512
//       float4 m_ViewportScaleOffset;  // Offset:  528
//       float4 m_ClipPlane;            // Offset:  544
//       float4 m_GlobalLightingScale;  // Offset:  560
//       float4 m_ViewSpaceLightingBackWS;// Offset:  576
//       float4 m_ThinGeomAAPixelScale; // Offset:  592
//
//   } g_Pass;                          // Offset:    0 Size:   608
//
// }
//
// cbuffer cb_g_DeferredLights
// {
//
//   struct DeferredLightingConsts
//   {
//       
//       struct OmniLightConsts
//       {
//           
//           float4 m_Position;         // Offset:    0
//           float4 m_Color;            // Offset:   16
//           float4 m_Attenuation;      // Offset:   32
//
//       } m_OmniLight;                 // Offset:    0
//       
//       struct DirectLightConsts
//       {
//           
//           float4 m_Direction;        // Offset:   48
//           float4 m_Color;            // Offset:   64
//
//       } m_DirectLight;               // Offset:   48
//       
//       struct SpotLightConsts
//       {
//           
//           float4 m_Position;         // Offset:   80
//           float4 m_Color;            // Offset:   96
//           float4 m_Attenuation;      // Offset:  112
//           float4 m_Direction;        // Offset:  128
//           float4 m_ConeAngles;       // Offset:  144
//           float4 m_PositionAtNearClip;// Offset:  160
//
//       } m_SpotLight;                 // Offset:   80
//       
//       struct ProjectorShadowParams
//       {
//           
//           float4x4 worldToLight[6];  // Offset:  176
//           float4 shadowMapScaleOffset[6];// Offset:  560
//           float4 noiseScale;         // Offset:  656
//
//       } m_Projections;               // Offset:  176
//       
//       struct ProjectorCookieParams
//       {
//           
//           float4x4 worldToCookie;    // Offset:  672
//           int4 cookieArrayIndex;     // Offset:  736
//
//       } m_Cookie;                    // Offset:  672
//       float4 m_BackgroundColor;      // Offset:  752
//       float4 m_DepthParams;          // Offset:  768
//       float4 m_EyeXAxis;             // Offset:  784
//       float4 m_EyeYAxis;             // Offset:  800
//       float4 m_EyeZAxis;             // Offset:  816
//       float4 m_VPOSToUVs_Resolve;    // Offset:  832
//       float4 m_EyeWorldPosition_Resolve;// Offset:  848
//       float4 m_WeatherExposedParams; // Offset:  864
//       float4x4 m_LightClipToWorldMat;// Offset:  880
//       float4 m_IsolateVars;          // Offset:  944
//       float m_EnvironmentSpecularScale;// Offset:  960
//
//   } g_DeferredLights;                // Offset:    0 Size:   964
//
// }
//
// cbuffer cb_g_VolumeCloudsShadow
// {
//
//   struct VolumetricCloudShadowConsts
//   {
//       
//       float4 CloudScale;             // Offset:    0
//       float4 CloudTranslate;         // Offset:   16
//       float4 CloudProject;           // Offset:   32
//       float4 UseCloudShadow;         // Offset:   48
//       float4 CloudShadowMipBias;     // Offset:   64
//
//   } g_VolumeCloudsShadow;            // Offset:    0 Size:    80
//
// }
//
// Resource bind info for g_IndoorGIVolumes
// {
//
//   float4x4 $Element;                 // Offset:    0 Size:    64
//
// }
//
// Resource bind info for g_WorldGICells
// {
//
//   struct GIIndirectionCell
//   {
//       
//       float3 WSToUnitScale;          // Offset:    0
//       float3 WSToUnitBias;           // Offset:   12
//       float3 UnitToVolumeScale;      // Offset:   24
//       float3 UnitToVolumeBias;       // Offset:   36
//       float NormalBiasScale;         // Offset:   48
//
//   } $Element;                        // Offset:    0 Size:    52
//
// }
//
// Resource bind info for g_SkySHConstants
// {
//
//   struct SkyLightingSH
//   {
//       
//       float4 Values[7];              // Offset:    0
//       float4 SkyLightingUp;          // Offset:  112
//       float4 SkyLightingScale;       // Offset:  128
//
//   } $Element;                        // Offset:    0 Size:   144
//
// }
//
//
// Resource Bindings:
//
// Name                                 Type  Format         Dim Slot Elements
// ------------------------------ ---------- ------- ----------- ---- --------
// s_g_WorldGIVolumeSampler          sampler      NA          NA    4        1
// s_LocalCubeMaps                   sampler      NA          NA    8        1
// s_PointClamp                      sampler      NA          NA   10        1
// s_TrilinearClamp                  sampler      NA          NA   12        1
// s_TrilinearWrap                   sampler      NA          NA   13        1
// s_LinearCmpWithBorder           sampler_c      NA          NA   15        1
// t_Albedo                          texture  float4          2d    0        1
// t_Normals                         texture  float4          2d    1        1
// t_DepthSurface                    texture  float4          2d    2        1
// t_SpecularReflectance             texture  float4          2d    3        1
// t_SSAO                            texture  float4          2d    4        1
// t_LocalCubeMaps                   texture  float4   cubearray    5        1
// t_Emissive                        texture  float4          2d   12        1
// t_g_SkyLightingCubeTexture        texture  float4        cube   13        1
// t_g_ShadowSampler                 texture  float4          2d   14        1
// t_MiscProps                       texture  float4          2d   15        1
// t_g_WorldGIVolume0                texture  float4          3d   20        1
// t_g_WorldGIVolume1                texture  float4          3d   21        1
// t_g_WorldGIVolume2                texture  float4          3d   22        1
// t_g_WorldGIVolume3                texture  float4          3d   23        1
// g_WorldGIIndirection              texture    uint          3d   24        1
// t_GlobalEnvMap                    texture  float4        cube   25        1
// g_IndoorGIVolumes                 texture  struct         r/o   26        1
// g_WorldGICells                    texture  struct         r/o   28        1
// g_VolumeIndex                     texture    uint          2d   29        1
// g_GILocalCubeMapsSRV              texture  float4         buf   48        1
// t_g_CloudShadowTexture            texture  float4          3d   54        1
// t_BRDFLUT                         texture  float4          2d   55        1
// g_SkySHConstants                  texture  struct         r/o   56        1
// cb_g_Frame                        cbuffer      NA          NA    1        1
// cb_g_Pass                         cbuffer      NA          NA    2        1
// cb_g_DeferredLights               cbuffer      NA          NA    5        1
// cb_g_VolumeCloudsShadow           cbuffer      NA          NA   10        1
//
//
//
// Input signature:
//
// Name                 Index   Mask Register SysValue  Format   Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_Position              0   xyzw        0      POS   float   xy  
// TEXCOORD                 0   xyzw        1     NONE    uint   xyz 
//
//
// Output signature:
//
// Name                 Index   Mask Register SysValue  Format   Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_Target                0   xyzw        0   TARGET   float   xyzw
// SV_Target                1   xyzw        1   TARGET   float   xyzw
//
ps_5_0
dcl_globalFlags refactoringAllowed
dcl_constantbuffer cb1[419], dynamicIndexed
dcl_constantbuffer cb2[36], immediateIndexed
dcl_constantbuffer cb5[61], immediateIndexed
dcl_constantbuffer cb10[5], immediateIndexed
dcl_sampler s4, mode_default
dcl_sampler s8, mode_default
dcl_sampler s10, mode_default
dcl_sampler s12, mode_default
dcl_sampler s13, mode_default
dcl_sampler s15, mode_comparison
dcl_resource_texture2d (float,float,float,float) t0
dcl_resource_texture2d (float,float,float,float) t1
dcl_resource_texture2d (float,float,float,float) t2
dcl_resource_texture2d (float,float,float,float) t3
dcl_resource_texture2d (float,float,float,float) t4
dcl_resource_texturecubearray (float,float,float,float) t5
dcl_resource_texture2d (float,float,float,float) t12
dcl_resource_texturecube (float,float,float,float) t13
dcl_resource_texture2d (float,float,float,float) t14
dcl_resource_texture2d (float,float,float,float) t15
dcl_resource_texture3d (float,float,float,float) t20
dcl_resource_texture3d (float,float,float,float) t21
dcl_resource_texture3d (float,float,float,float) t22
dcl_resource_texture3d (float,float,float,float) t23
dcl_resource_texture3d (uint,uint,uint,uint) t24
dcl_resource_texturecube (float,float,float,float) t25
dcl_resource_structured t26, 64 
dcl_resource_structured t28, 52 
dcl_resource_texture2d (uint,uint,uint,uint) t29
dcl_resource_buffer (float,float,float,float) t48
dcl_resource_texture3d (float,float,float,float) t54
dcl_resource_texture2d (float,float,float,float) t55
dcl_resource_structured t56, 144 
dcl_input_ps_siv linear noperspective v0.xy, position
dcl_input_ps constant v1.xyz
dcl_output o0.xyzw
dcl_output o1.xyzw
dcl_temps 25
mul r0.xy, v0.xyxx, cb2[32].xyxx
sample_l_indexable(texture2d)(float,float,float,float) r1.z, r0.xyxx, t2.yzxw, s10, l(0.000000)
mad r1.xy, r0.xyxx, l(2.000000, -2.000000, 0.000000, 0.000000), l(-1.000000, 1.000000, 0.000000, 0.000000)
mov r1.w, l(1.000000)
dp4 r2.x, r1.xyzw, cb2[23].xyzw
dp4 r2.y, r1.xyzw, cb2[24].xyzw
dp4 r2.z, r1.xyzw, cb2[25].xyzw
dp4 r0.z, r1.xyzw, cb2[26].xyzw
div r1.xyz, r2.xyzx, r0.zzzz
mov r1.w, l(1.000000)
dp4 r2.x, r1.xyzw, cb2[2].xyzw
dp4 r2.y, r1.xyzw, cb2[3].xyzw
dp4 r2.z, r1.xyzw, cb2[4].xyzw
sample_l_indexable(texture2d)(float,float,float,float) r1.xyzw, r0.xyxx, t0.xyzw, s10, l(0.000000)
sample_l_indexable(texture2d)(float,float,float,float) r3.xyzw, r0.xyxx, t1.xyzw, s10, l(0.000000)
sample_l_indexable(texture2d)(float,float,float,float) r4.xyzw, r0.xyxx, t3.yxzw, s10, l(0.000000)
sample_l_indexable(texture2d)(float,float,float,float) r5.xyzw, r0.xyxx, t15.xyzw, s10, l(0.000000)
mad r3.xyz, r3.xyzx, l(2.000000, 2.000000, 2.000000, 0.000000), l(-1.000000, -1.000000, -1.000000, 0.000000)
dp3 r0.z, r3.xyzx, r3.xyzx
rsq r0.z, r0.z
mul r6.xyz, r0.zzzz, r3.xyzx
max r0.z, r1.w, l(0.000010)
log r0.z, r0.z
mul r0.z, r0.z, l(2.200000)
exp r0.z, r0.z
mul r0.w, r3.w, l(19.000000)
exp r3.x, r0.w
mad r0.w, r3.x, l(0.500000), l(1.000000)
div r7.y, l(1.000000, 1.000000, 1.000000, 1.000000), r0.w
mul r0.w, r5.w, l(255.000000)
ftou r0.w, r0.w
ieq r0.w, r0.w, l(255)
if_nz r0.w
  lt r1.w, l(0.000100), r4.w
  sqrt r8.xyz, r1.xyzx
  movc r1.xyz, r1.wwww, r8.xyzx, r1.xyzx
  mad r8.xyz, r5.xyzx, l(2.000000, 2.000000, 2.000000, 0.000000), l(-1.000000, -1.000000, -1.000000, 0.000000)
  dp3 r1.w, r8.xyzx, r8.xyzx
  rsq r1.w, r1.w
  mul r8.xyz, r1.wwww, r8.xyzx
  mul r1.w, r4.y, l(19.000000)
  exp r3.y, r1.w
  mov r9.xyz, l(0,0,0,0)
  mov r10.xyz, r0.zzzz
  mov r11.y, l(0)
  mov r0.z, l(1.000000)
  mov r5.xz, l(0,0,0,0)
else 
  sample_l_indexable(texture2d)(float,float,float,float) r9.xyz, r0.xyxx, t12.xyzw, s10, l(0.000000)
  mov r10.xyz, r4.yxzy
  mov r8.xyz, l(1.000000,1.000000,1.000000,0)
  mov r1.xyz, l(0,0,0,0)
  mov r11.y, r5.y
  mov r3.y, l(1.000000)
  mov r4.xz, l(1.000000,0,0,0)
endif 
movc r1.w, r0.w, r4.x, l(1.000000)
sample_indexable(texture2d)(float,float,float,float) r0.x, r0.xyxx, t4.xyzw, s10
add r4.xyw, -r2.xyxz, cb2[0].xyxz
mov r2.w, l(1.000000)
dp4 r12.x, r2.xyzw, cb1[27].xyzw
dp4 r12.y, r2.xyzw, cb1[28].xyzw
dp4 r12.z, r2.xyzw, cb1[29].xyzw
mad r13.xyz, r12.xyzx, cb1[13].xyzx, cb1[9].xyzx
mad r14.xyz, r12.xyzx, cb1[14].xyzx, cb1[10].xyzx
mad r15.xyz, r12.xyzx, cb1[15].xyzx, cb1[11].xyzx
mad r12.xyz, r12.xyzx, cb1[16].xyzx, cb1[12].xyzx
ieq r5.yw, v1.xxxx, l(0, 1, 0, 2)
mov r16.x, r15.z
mov r16.yz, l(0,0.250000,0.750000,0)
mov r12.w, l(0.750000)
movc r16.xyz, r5.wwww, r16.xyzx, r12.zwwz
movc r12.xyzw, r5.wwww, r15.yxxx, r12.yxxx
mov r15.x, r14.z
mov r15.yz, l(0,0.750000,0.250000,0)
movc r15.xyz, r5.yyyy, r15.xyzx, r16.xyzx
movc r12.xyzw, r5.yyyy, r14.yxxx, r12.xyzw
mov r13.w, l(0.250000)
movc r14.xyz, v1.xxxx, r15.xyzx, r13.zwwz
movc r12.xyzw, v1.xxxx, r12.xyzw, r13.yxxx
mad r12.xyzw, r12.xyzw, l(0.250000, 0.250000, 0.250000, 0.250000), r14.zyyy
div r5.yw, l(1.000000, 1.000000, 1.000000, 1.000000), cb1[8].xxxy
div r12.xyzw, r12.xyzw, r5.wyyy
add r12.xyzw, r12.xyzw, l(-2.500000, -2.500000, -2.500000, -2.500000)
round_ni r7.zw, r12.wwwx
add r12.xyzw, -r7.wzzz, r12.xyzw
mul r5.yw, r5.yyyw, r7.zzzw
ne r13.xyz, l(0.000000, 0.000000, 0.000000, 0.000000), cb1[21].xyzx
if_nz r13.x
  gather4_c_aoffimmi_indexable(1,1,0)(texture2d)(float,float,float,float) r15.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(3,1,0)(texture2d)(float,float,float,float) r16.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(5,1,0)(texture2d)(float,float,float,float) r17.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  add r18.xyzw, -r12.wwxw, l(0.535534, 1.535534, 1.000000, 1.000000)
  add_sat r7.zw, -r12.xxxx, r18.xxxy
  mul r0.y, r7.z, r7.z
  mul r0.y, r15.w, r0.y
  min r11.zw, r7.wwww, r18.zzzw
  mov_sat r18.xy, r18.xyxx
  add r13.xw, -r18.xxxy, l(1.000000, 0.000000, 0.000000, 1.000000)
  min r3.z, r11.z, r13.x
  mad r7.z, -r3.z, l(0.500000), r11.z
  mul r3.z, r3.z, r7.z
  mad r3.z, r11.z, r18.x, r3.z
  add_sat r7.z, -r12.x, l(0.535534)
  add r8.w, -r7.z, l(1.000000)
  min r9.w, r8.w, r11.w
  mad r10.w, -r9.w, l(0.500000), r11.w
  mul r9.w, r9.w, r10.w
  mad r9.w, r11.w, r7.z, r9.w
  add r10.w, -r12.w, -r12.x
  add_sat r10.w, r10.w, l(2.535534)
  add r11.z, -r7.w, l(1.000000)
  min r11.z, r10.w, r11.z
  mad r11.w, -r11.z, l(0.500000), r10.w
  mul r11.z, r11.z, r11.w
  mad r7.w, r10.w, r7.w, r11.z
  mul r3.z, r3.z, r15.z
  mad r0.y, r0.y, l(0.500000), r3.z
  mad r0.y, r15.x, r9.w, r0.y
  mad r0.y, r15.y, r7.w, r0.y
  min r3.z, r13.w, r18.z
  mad r7.w, -r3.z, l(0.500000), r18.z
  mul r3.z, r3.z, r7.w
  mad r3.z, r18.z, r18.y, r3.z
  add_sat r7.w, r12.w, l(0.535534)
  add r9.w, -r7.w, l(1.000000)
  min r9.w, r9.w, r18.z
  mad r10.w, -r9.w, l(0.500000), r18.z
  mul r9.w, r9.w, r10.w
  mad r7.w, r18.z, r7.w, r9.w
  add r9.w, r12.x, r12.w
  add_sat r9.w, r9.w, l(-1.535534)
  mul r9.w, r9.w, r9.w
  mad r9.w, -r9.w, l(0.500000), l(1.000000)
  add r10.w, r12.x, r18.w
  add_sat r10.w, r10.w, l(-1.535534)
  mul r10.w, r10.w, r10.w
  mad r10.w, -r10.w, l(0.500000), l(1.000000)
  mad r0.y, r16.w, r3.z, r0.y
  mad r0.y, r16.z, r7.w, r0.y
  mad r0.y, r16.x, r9.w, r0.y
  mad r0.y, r16.y, r10.w, r0.y
  add r11.zw, -r18.wwww, l(0.000000, 0.000000, 0.535534, 1.000000)
  add_sat r3.z, -r12.x, r11.z
  mul r3.z, r3.z, r3.z
  mul r3.z, r17.z, r3.z
  add r7.w, -r12.x, -r18.w
  add_sat r13.xw, r7.wwww, l(1.535534, 0.000000, 0.000000, 2.535534)
  min r7.w, r13.x, r18.z
  mov_sat r11.z, r11.z
  add r9.w, -r11.z, l(1.000000)
  min r9.w, r7.w, r9.w
  mad r10.w, -r9.w, l(0.500000), r7.w
  mul r9.w, r9.w, r10.w
  mad r7.w, r7.w, r11.z, r9.w
  min r9.w, r11.w, r13.x
  min r8.w, r8.w, r9.w
  mad r10.w, -r8.w, l(0.500000), r9.w
  mul r8.w, r8.w, r10.w
  mad r7.z, r9.w, r7.z, r8.w
  add r8.w, -r13.x, l(1.000000)
  min r8.w, r8.w, r13.w
  mad r9.w, -r8.w, l(0.500000), r13.w
  mul r8.w, r8.w, r9.w
  mad r8.w, r13.w, r13.x, r8.w
  mad r0.y, r17.w, r7.w, r0.y
  mad r0.y, r3.z, l(0.500000), r0.y
  mad r0.y, r17.x, r8.w, r0.y
  mad r0.y, r17.y, r7.z, r0.y
else 
  mov r0.y, l(0)
endif 
if_nz r13.y
  gather4_c_aoffimmi_indexable(1,3,0)(texture2d)(float,float,float,float) r15.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(3,3,0)(texture2d)(float,float,float,float) r16.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(5,3,0)(texture2d)(float,float,float,float) r17.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  add r13.xyw, -r12.xwxx, l(1.535534, 1.000000, 0.000000, 1.000000)
  mov_sat r13.x, r13.x
  add r3.z, -r13.x, l(1.000000)
  min r7.z, r3.z, r13.y
  mad r7.w, -r7.z, l(0.500000), r13.y
  mul r7.z, r7.z, r7.w
  mad r7.z, r13.y, r13.x, r7.z
  add_sat r7.w, r12.x, l(0.535534)
  add r8.w, -r7.w, l(1.000000)
  min r9.w, r8.w, r13.y
  mad r10.w, -r9.w, l(0.500000), r13.y
  mul r9.w, r9.w, r10.w
  mad r9.w, r13.y, r7.w, r9.w
  add r10.w, r12.w, r12.x
  add_sat r10.w, r10.w, l(-1.535534)
  mul r10.w, r10.w, r10.w
  mad r10.w, -r10.w, l(0.500000), l(1.000000)
  add r11.zw, r12.wwwx, r13.wwwy
  add_sat r11.zw, r11.zzzw, l(0.000000, 0.000000, -1.535534, -1.535534)
  mul r11.zw, r11.zzzw, r11.zzzw
  mad r11.zw, -r11.zzzw, l(0.000000, 0.000000, 0.500000, 0.500000), l(0.000000, 0.000000, 1.000000, 1.000000)
  mad r7.z, r15.w, r7.z, r0.y
  mad r7.z, r15.z, r10.w, r7.z
  mad r7.z, r15.x, r9.w, r7.z
  mad r7.z, r15.y, r11.z, r7.z
  add r7.z, r16.w, r7.z
  add r7.z, r16.z, r7.z
  add r7.z, r16.x, r7.z
  add r7.z, r16.y, r7.z
  add r9.w, -r13.y, l(1.000000)
  min r3.z, r3.z, r9.w
  mad r10.w, -r3.z, l(0.500000), r9.w
  mul r3.z, r3.z, r10.w
  mad r3.z, r9.w, r13.x, r3.z
  min r8.w, r8.w, r9.w
  mad r10.w, -r8.w, l(0.500000), r9.w
  mul r8.w, r8.w, r10.w
  mad r7.w, r9.w, r7.w, r8.w
  add r8.w, r13.y, r13.w
  add_sat r8.w, r8.w, l(-1.535534)
  mul r8.w, r8.w, r8.w
  mad r8.w, -r8.w, l(0.500000), l(1.000000)
  mad r7.z, r17.w, r11.w, r7.z
  mad r3.z, r17.z, r3.z, r7.z
  mad r3.z, r17.x, r8.w, r3.z
  mad r0.y, r17.y, r7.w, r3.z
endif 
if_nz r13.z
  gather4_c_aoffimmi_indexable(1,5,0)(texture2d)(float,float,float,float) r13.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(3,5,0)(texture2d)(float,float,float,float) r15.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  gather4_c_aoffimmi_indexable(5,5,0)(texture2d)(float,float,float,float) r14.xyzw, r5.ywyy, t14.xyzw, s15.x, r14.x
  add r16.xyzw, -r12.yzxw, l(0.535534, 1.535534, 1.000000, 1.000000)
  add_sat r5.yw, -r16.zzzz, r16.xxxy
  mul r3.z, r5.y, r5.y
  mul r3.z, r13.x, r3.z
  add r17.xyzw, -r16.zzww, l(1.000000, 0.535534, 0.535534, 1.000000)
  min r5.y, r5.w, r17.x
  mov_sat r16.xy, r16.xyxx
  add r7.zw, -r16.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
  min r7.z, r5.y, r7.z
  mad r8.w, -r7.z, l(0.500000), r5.y
  mul r7.z, r7.z, r8.w
  mad r5.y, r5.y, r16.x, r7.z
  min r7.z, r5.w, r16.w
  mov_sat r11.zw, r17.yyyz
  add r12.xy, -r11.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
  min r8.w, r7.z, r12.x
  mad r9.w, -r8.w, l(0.500000), r7.z
  mul r8.w, r8.w, r9.w
  mad r7.z, r7.z, r11.z, r8.w
  add r8.w, -r12.w, -r16.z
  add_sat r8.w, r8.w, l(2.535534)
  add r9.w, -r5.w, l(1.000000)
  min r9.w, r8.w, r9.w
  mad r10.w, -r9.w, l(0.500000), r8.w
  mul r9.w, r9.w, r10.w
  mad r5.w, r8.w, r5.w, r9.w
  mad r7.z, r13.w, r7.z, r0.y
  mad r5.w, r13.z, r5.w, r7.z
  mad r3.z, r3.z, l(0.500000), r5.w
  mad r3.z, r13.y, r5.y, r3.z
  min r5.y, r7.w, r17.x
  mad r5.w, -r5.y, l(0.500000), r17.x
  mul r5.y, r5.y, r5.w
  mad r5.y, r17.x, r16.y, r5.y
  add_sat r5.w, r12.w, l(0.535534)
  add r7.z, -r5.w, l(1.000000)
  min r7.z, r7.z, r17.x
  mad r7.w, -r7.z, l(0.500000), r17.x
  mul r7.z, r7.z, r7.w
  mad r5.w, r17.x, r5.w, r7.z
  add r7.z, r12.w, r16.z
  add_sat r7.z, r7.z, l(-1.535534)
  mul r7.z, r7.z, r7.z
  mad r7.z, -r7.z, l(0.500000), l(1.000000)
  add r7.w, r16.z, r16.w
  add_sat r7.w, r7.w, l(-1.535534)
  mul r7.w, r7.w, r7.w
  mad r7.w, -r7.w, l(0.500000), l(1.000000)
  mad r3.z, r15.w, r7.z, r3.z
  mad r3.z, r15.z, r7.w, r3.z
  mad r3.z, r15.x, r5.y, r3.z
  mad r3.z, r15.y, r5.w, r3.z
  add_sat r5.y, -r16.z, r17.z
  mul r5.y, r5.y, r5.y
  mul r5.y, r14.y, r5.y
  add r5.w, -r16.w, -r16.z
  add_sat r7.zw, r5.wwww, l(0.000000, 0.000000, 1.535534, 2.535534)
  min r12.zw, r7.zzzz, r17.wwwx
  min r12.xy, r12.xyxx, r12.zwzz
  mad r13.xy, -r12.xyxx, l(0.500000, 0.500000, 0.000000, 0.000000), r12.zwzz
  mul r12.xy, r12.xyxx, r13.xyxx
  mad r11.zw, r12.zzzw, r11.zzzw, r12.xxxy
  add r5.w, -r7.z, l(1.000000)
  min r5.w, r5.w, r7.w
  mad r8.w, -r5.w, l(0.500000), r7.w
  mul r5.w, r5.w, r8.w
  mad r5.w, r7.w, r7.z, r5.w
  mad r3.z, r14.w, r5.w, r3.z
  mad r3.z, r14.z, r11.z, r3.z
  mad r3.z, r14.x, r11.w, r3.z
  mad r0.y, r5.y, l(0.500000), r3.z
endif 
mul r0.y, r0.y, l(0.048284)
dp3 r3.z, r4.xywx, r4.xywx
ne r5.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb10[3].x
if_nz r5.y
  mad r12.xyz, r2.xyzx, cb10[0].xyzx, cb10[1].xyzx
  mul r5.y, r12.z, cb10[2].z
  mad r12.xy, cb10[2].xyxx, r5.yyyy, r12.xyxx
  mov r12.z, cb10[1].w
  sample_l_indexable(texture3d)(float,float,float,float) r5.y, r12.xyzx, t54.xyzw, s13, cb10[4].x
  mad_sat r5.w, r3.z, cb10[3].z, cb10[3].w
  add r7.z, -cb10[3].y, l(1.000000)
  mad r5.w, r5.w, r7.z, cb10[3].y
  add r5.y, r5.y, l(-1.000000)
  mad r5.y, r5.w, r5.y, l(1.000000)
else 
  mov r5.y, l(1.000000)
endif 
mul r0.y, r0.y, r5.y
dp3 r5.w, cb5[3].xyzx, r8.xyzx
mad r12.xyz, -r5.wwww, r8.xyzx, cb5[3].xyzx
dp3 r5.w, r12.xyzx, r12.xyzx
rsq r5.w, r5.w
mul r12.xyz, r5.wwww, r12.xyzx
movc r12.xyz, r0.wwww, r12.xyzx, r6.xyzx
rsq r3.z, r3.z
mul r13.xyz, r3.zzzz, r4.xywx
mad r4.xyw, r4.xyxw, r3.zzzz, cb5[3].xyxz
dp3 r3.z, r4.xywx, r4.xywx
rsq r3.z, r3.z
mul r4.xyw, r3.zzzz, r4.xyxw
dp3 r3.z, r12.xyzx, cb5[3].xyzx
dp3_sat r7.x, r12.xyzx, r13.xyzx
dp3 r5.w, r12.xyzx, r4.xywx
mad r11.x, r3.z, l(0.500000), l(0.500000)
mad r7.zw, r11.xxxy, l(0.000000, 0.000000, 0.968750, 0.968750), l(0.000000, 0.000000, 0.015625, 0.015625)
sample_l_indexable(texture2d)(float,float,float,float) r7.z, r7.zwzz, t55.xyzw, s12, l(0.000000)
mov_sat r7.w, -r3.z
mul r5.z, r5.z, r7.w
mul r11.xyz, r0.yyyy, cb5[4].xyzx
mul r14.xyz, r7.zzzz, r11.xyzx
mad r11.xyz, r5.zzzz, r11.xyzx, r14.xyzx
mul r11.xyz, r1.wwww, r11.xyzx
dp3 r0.y, r14.xyzx, l(0.212600, 0.715200, 0.072200, 0.000000)
if_nz r0.w
  add r7.zw, r3.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
  sqrt r7.zw, r7.zzzw
  mul r7.zw, r7.zzzw, l(0.000000, 0.000000, 0.125000, 0.125000)
  dp3 r5.z, r4.xywx, r8.xyzx
  mul r5.z, r5.z, r5.z
  mul r3.xy, r3.xyxx, r5.zzzz
  add r5.z, r5.w, l(1.000000)
  div r3.xy, -r3.xyxx, r5.zzzz
  mul r3.xy, r3.xyxx, l(1.442695, 1.442695, 0.000000, 0.000000)
  exp r3.xy, r3.xyxx
  mul r3.xy, r3.xyxx, r7.zwzz
  mul r8.xyz, r10.xyzx, r3.xxxx
  mul r3.x, r4.z, r3.y
  mad r8.xyz, r8.xyzx, r1.xyzx, r3.xxxx
  mul r8.xyz, r14.xyzx, r8.xyzx
else 
  mov_sat r3.z, r3.z
  mov_sat r5.w, r5.w
  dp3_sat r3.x, r13.xyzx, r4.xywx
  add r3.y, r7.y, l(-1.000000)
  mul r4.x, r5.w, r5.w
  mad r3.y, r4.x, r3.y, l(1.000000)
  mul r3.y, r3.y, r3.y
  div r3.y, r7.y, r3.y
  add r4.yzw, -r10.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
  add r3.x, -r3.x, l(1.000000)
  mul r5.z, r3.x, r3.x
  mul r5.z, r5.z, r5.z
  mul r3.x, r3.x, r5.z
  mad r4.yzw, r4.yyzw, r3.xxxx, r10.xxyz
  add r3.x, -r7.y, l(1.000000)
  mad r5.z, r3.z, r3.x, r7.y
  sqrt r5.z, r5.z
  add r3.z, r3.z, r5.z
  div r3.z, l(1.000000, 1.000000, 1.000000, 1.000000), r3.z
  mad r3.x, r7.x, r3.x, r7.y
  sqrt r3.x, r3.x
  add r3.x, r3.x, r7.x
  div r3.x, l(1.000000, 1.000000, 1.000000, 1.000000), r3.x
  mul r3.x, r3.x, r3.z
  mul r3.z, r3.x, r3.y
  lt r5.z, l(0.000000), r5.x
  mad r5.w, -r5.w, r5.w, l(1.000100)
  mul r7.z, r5.w, r5.w
  div r4.x, r4.x, r5.w
  div r4.x, -r4.x, r7.y
  mul r4.x, r4.x, l(1.442695)
  exp r4.x, r4.x
  mul r4.x, r4.x, l(4.000000)
  div r4.x, r4.x, r7.z
  add r4.x, r4.x, l(1.000000)
  mad r5.w, r7.y, l(4.000000), l(1.000000)
  div r4.x, r4.x, r5.w
  mad r3.x, -r3.y, r3.x, r4.x
  mad r3.x, r5.x, r3.x, r3.z
  movc r3.x, r5.z, r3.x, r3.z
  mul r4.xyz, r0.zzzz, r4.yzwy
  mul r4.xyz, r0.xxxx, r4.xyzx
  mul r3.xyz, r3.xxxx, r4.xyzx
  mul r8.xyz, r3.xyzx, r14.xyzx
endif 
ne r3.x, l(0.000000, 0.000000, 0.000000, 0.000000), cb5[59].x
if_nz r3.x
  dp3 r3.x, -r13.xyzx, r12.xyzx
  add r3.x, r3.x, r3.x
  mad r4.xyz, r12.xyzx, -r3.xxxx, -r13.xyzx
  mul r3.xyz, r6.xyzx, cb1[41].yyyy
  mad r12.xyz, r3.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r2.xyzx
  mad r3.xyz, r12.xyzx, cb1[42].xyzx, cb1[43].xyzx
  ftou r13.xyz, r3.xyzx
  mov r13.w, l(0)
  ld_indexable(texture3d)(uint,uint,uint,uint) r3.x, r13.xyzw, t24.xyzw
  if_nz r3.x
    ftou r13.xy, v0.xyxx
    mov r13.zw, l(0,0,0,0)
    ld_indexable(texture2d)(uint,uint,uint,uint) r3.y, r13.xyzw, t29.yxzw
    iadd r3.z, r3.x, l(-1)
    ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r13.xyzw, r3.z, l(0), t28.xyzw
    ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r14.xyzw, r3.z, l(16), t28.zwxy
    ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r15.xyzw, r3.z, l(32), t28.xyzw
    ld_structured_indexable(structured_buffer, stride=52)(mixed,mixed,mixed,mixed) r3.z, r3.z, l(48), t28.xxxx
    mov r16.x, r13.w
    mov r16.yz, r14.zzwz
    mad r13.xyz, r12.xyzx, r13.xyzx, r16.xyzx
    mul r16.xyz, r3.zzzz, r6.xyzx
    mad_sat r13.xyz, r16.xyzx, cb1[41].yyyy, r13.xyzx
    mov r14.z, r15.x
    mad r13.xyz, r13.xyzx, r14.xyzx, r15.yzwy
    sample_l_indexable(texture3d)(float,float,float,float) r14.xyzw, r13.xyzx, t20.xyzw, s4, l(0.000000)
    sample_l_indexable(texture3d)(float,float,float,float) r15.xyzw, r13.xyzx, t21.xyzw, s4, l(0.000000)
    sample_l_indexable(texture3d)(float,float,float,float) r16.xyzw, r13.xyzx, t22.xyzw, s4, l(0.000000)
    sample_l_indexable(texture3d)(float,float,float,float) r13.xyzw, r13.xyzx, t23.xyzw, s4, l(0.000000)
    and r3.z, r3.y, l(0x0000ffff)
    if_nz r3.z
      and r3.z, r3.y, l(255)
      iadd r3.z, r3.z, l(-1)
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r17.xyzw, r3.z, l(0), t26.xyzw
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r18.xyzw, r3.z, l(16), t26.xyzw
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r19.xyzw, r3.z, l(32), t26.xyzw
      mov r12.w, l(1.000000)
      dp4 r17.x, r12.xyzw, r17.xyzw
      dp4 r17.y, r12.xyzw, r18.xyzw
      dp4 r17.z, r12.xyzw, r19.xyzw
      ubfe r3.z, l(8), l(8), r3.y
      utof r3.z, r3.z
      mul r3.z, r3.z, l(0.003922)
      sample_l_indexable(texture3d)(float,float,float,float) r18.xyzw, r17.xyzx, t20.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r19.xyzw, r17.xyzx, t21.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r20.xyzw, r17.xyzx, t22.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r17.xyzw, r17.xyzx, t23.xyzw, s4, l(0.000000)
      add r18.xyzw, -r14.xyzw, r18.xyzw
      mad r14.xyzw, r3.zzzz, r18.xyzw, r14.xyzw
      add r18.xyzw, -r15.xyzw, r19.xyzw
      mad r15.xyzw, r3.zzzz, r18.xyzw, r15.xyzw
      add r18.xyzw, -r16.xyzw, r20.xyzw
      mad r16.xyzw, r3.zzzz, r18.xyzw, r16.xyzw
      add r17.xyzw, -r13.xyzw, r17.xyzw
      mad r13.xyzw, r3.zzzz, r17.xyzw, r13.xyzw
    else 
      mov r3.z, l(0)
    endif 
    ushr r5.z, r3.y, l(16)
    if_nz r5.z
      ubfe r3.y, l(8), l(16), r3.y
      iadd r3.y, r3.y, l(-1)
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r17.xyzw, r3.y, l(0), t26.xyzw
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r18.xyzw, r3.y, l(16), t26.xyzw
      ld_structured_indexable(structured_buffer, stride=64)(mixed,mixed,mixed,mixed) r19.xyzw, r3.y, l(32), t26.xyzw
      mov r12.w, l(1.000000)
      dp4 r17.x, r12.xyzw, r17.xyzw
      dp4 r17.y, r12.xyzw, r18.xyzw
      dp4 r17.z, r12.xyzw, r19.xyzw
      ushr r3.y, r5.z, l(8)
      utof r3.y, r3.y
      mul r3.y, r3.y, l(0.003922)
      sample_l_indexable(texture3d)(float,float,float,float) r12.xyzw, r17.xyzx, t20.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r18.xyzw, r17.xyzx, t21.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r19.xyzw, r17.xyzx, t22.xyzw, s4, l(0.000000)
      sample_l_indexable(texture3d)(float,float,float,float) r17.xyzw, r17.xyzx, t23.xyzw, s4, l(0.000000)
      add r3.z, -r3.z, l(1.000000)
      min r3.y, r3.z, r3.y
      add r12.xyzw, -r14.xyzw, r12.xyzw
      mad r14.xyzw, r3.yyyy, r12.xyzw, r14.xyzw
      add r12.xyzw, -r15.xyzw, r18.xyzw
      mad r15.xyzw, r3.yyyy, r12.xyzw, r15.xyzw
      add r12.xyzw, -r16.xyzw, r19.xyzw
      mad r16.xyzw, r3.yyyy, r12.xyzw, r16.xyzw
      add r12.xyzw, -r13.xyzw, r17.xyzw
      mad r13.xyzw, r3.yyyy, r12.xyzw, r13.xyzw
    endif 
    mul r3.y, r5.y, cb2[35].y
    mul r12.xyzw, r3.yyyy, r14.xyzw
    mul r14.xyzw, r3.yyyy, r15.xyzw
    mul r15.xyzw, r3.yyyy, r16.xyzw
    mov r6.w, l(1.000000)
    dp4 r16.x, r12.xyzw, r6.xyzw
    dp4 r16.y, r14.xyzw, r6.xyzw
    dp4 r16.z, r15.xyzw, r6.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r17.xyzw, l(0), l(0), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r18.xyzw, l(0), l(16), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r19.xyzw, l(0), l(32), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r20.xyzw, l(0), l(48), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r21.xyzw, l(0), l(64), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r22.xyzw, l(0), l(80), t56.xyzw
    ld_structured_indexable(structured_buffer, stride=144)(mixed,mixed,mixed,mixed) r5.yzw, l(0), l(96), t56.xxyz
    dp4 r23.x, r17.xyzw, r6.xyzw
    dp4 r23.y, r18.xyzw, r6.xyzw
    dp4 r23.z, r19.xyzw, r6.xyzw
    mul r24.xyzw, r6.yzzz, r6.xyzx
    dp4 r20.x, r20.xyzw, r24.xyzw
    dp4 r20.y, r21.xyzw, r24.xyzw
    dp4 r20.z, r22.xyzw, r24.xyzw
    mul r3.y, r6.y, r6.y
    mad r3.y, r6.x, r6.x, -r3.y
    add r20.xyz, r20.xyzx, r23.xyzx
    mad r5.yzw, r5.yyzw, r3.yyyy, r20.xxyz
    max r5.yzw, r5.yyzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    dp4 r3.y, r13.xyzw, r6.xyzw
    mad r5.yzw, r5.yyzw, r3.yyyy, r16.xxyz
    mov r4.w, l(1.000000)
    dp4 r3.y, r13.xyzw, r4.xyzw
    dp4 r12.x, r12.xyzw, r4.xyzw
    dp4 r12.y, r14.xyzw, r4.xyzw
    dp4 r12.z, r15.xyzw, r4.xyzw
    dp4 r13.x, r17.xyzw, r4.xyzw
    dp4 r13.y, r18.xyzw, r4.xyzw
    dp4 r13.z, r19.xyzw, r4.xyzw
    max r13.xyz, r13.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
    mad r12.xyz, r13.xyzx, r3.yyyy, r12.xyzx
    dp3 r3.z, r12.xyzx, l(0.212600, 0.715200, 0.072200, 0.000000)
  else 
    mov r5.yzw, l(0,0,0,0)
    mov r3.yz, l(0,1.000000,1.000000,0)
  endif 
  ne r6.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb1[41].x
  not r6.w, r6.w
  ieq r3.x, r3.x, l(0)
  or r3.x, r3.x, r6.w
  if_nz r3.x
    sample_l_indexable(texturecube)(float,float,float,float) r5.yzw, r6.xyzx, t13.wxyz, s12, l(0.000000)
    dp3 r3.z, r5.yzwy, l(0.212600, 0.715200, 0.072200, 0.000000)
    mad r3.y, r6.z, l(0.500000), l(0.500000)
  endif 
  mul r5.yzw, r0.xxxx, r5.yyzw
  mul r0.x, r0.x, r0.z
  dp3 r3.x, r5.yzwy, l(0.212600, 0.715200, 0.072200, 0.000000)
  mad r3.w, -r3.w, l(6.333333), l(6.333333)
  imul null, r6.xy, v1.yzyy, l(10, 10, 0, 0)
  dp4 r12.x, r2.xyzw, cb1[r6.x + 53].xyzw
  dp4 r12.y, r2.xyzw, cb1[r6.x + 54].xyzw
  dp4 r12.z, r2.xyzw, cb1[r6.x + 55].xyzw
  dp4 r13.x, r2.xyzw, cb1[r6.y + 53].xyzw
  dp4 r13.y, r2.xyzw, cb1[r6.y + 54].xyzw
  dp4 r13.z, r2.xyzw, cb1[r6.y + 55].xyzw
  add r14.xyz, |r12.xyzx|, -cb1[r6.x + 50].xyzx
  add r15.xyz, -cb1[r6.x + 50].xyzx, cb1[r6.x + 51].xyzx
  div r14.xyz, r14.xyzx, r15.xyzx
  add r15.xyz, |r13.xyzx|, -cb1[r6.y + 50].xyzx
  add r16.xyz, -cb1[r6.y + 50].xyzx, cb1[r6.y + 51].xyzx
  div r15.xyz, r15.xyzx, r16.xyzx
  lt r16.xyz, r14.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
  and r2.w, r16.y, r16.x
  and r2.w, r16.z, r2.w
  lt r16.xyz, r15.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
  and r6.z, r16.y, r16.x
  and r6.z, r16.z, r6.z
  mov_sat r14.xyz, r14.xyzx
  max r6.w, r14.y, r14.x
  max r6.w, r14.z, r6.w
  add r7.z, r6.w, l(0.000100)
  add r14.xy, -r6.wwww, l(1.000000, 1.000100, 0.000000, 0.000000)
  mov_sat r15.xyz, r15.xyzx
  max r7.w, r15.y, r15.x
  max r7.w, r15.z, r7.w
  add r7.z, r7.w, r7.z
  add r8.w, -r7.w, l(1.000000)
  add r9.w, r8.w, r14.y
  div r6.w, r6.w, r7.z
  add r6.w, -r6.w, l(1.000000)
  div r10.w, r14.x, r9.w
  mul r11.w, r6.w, r10.w
  div r7.z, r7.w, r7.z
  add r7.z, -r7.z, l(1.000000)
  div r7.w, r8.w, r9.w
  mul r7.z, r7.w, r7.z
  mad r6.w, r6.w, r10.w, r7.z
  eq r7.w, r6.w, l(0.000000)
  div r6.w, l(1.000000, 1.000000, 1.000000, 1.000000), r6.w
  movc r6.w, r7.w, l(1.000000), r6.w
  mul r14.y, r6.w, r11.w
  mul r14.z, r6.w, r7.z
  min r6.w, r9.w, l(0.900000)
  mul r14.x, r6.w, l(1.111111)
  movc r14.xyz, r6.zzzz, l(1.000000,0,1.000000,0), r14.xyzx
  movc r14.xyz, r2.wwww, l(1.000000,1.000000,0,0), r14.xyzx
  ld_indexable(buffer)(float,float,float,float) r15.xyzw, v1.yyyy, t48.xyzw
  mov r4.w, l(1.000000)
  dp4_sat r2.w, r15.xyzw, r4.xyzw
  div_sat r2.w, r3.z, r2.w
  ld_indexable(buffer)(float,float,float,float) r15.xyzw, v1.zzzz, t48.xyzw
  dp4_sat r4.w, r15.xyzw, r4.xyzw
  div_sat r3.z, r3.z, r4.w
  mul r2.w, r2.w, r14.y
  dp3 r15.x, r4.xyzx, cb1[r6.x + 53].xyzx
  dp3 r15.y, r4.xyzx, cb1[r6.x + 54].xyzx
  dp3 r15.z, r4.xyzx, cb1[r6.x + 55].xyzx
  add r16.xyz, -r12.xyzx, cb1[r6.x + 48].xyzx
  div r16.xyz, r16.xyzx, r15.xyzx
  add r12.xyz, -r12.xyzx, cb1[r6.x + 49].xyzx
  div r12.xyz, r12.xyzx, r15.xyzx
  max r12.xyz, r12.xyzx, r16.xyzx
  min r4.w, r12.y, r12.x
  min r4.w, r12.z, r4.w
  mad r12.xyz, r4.xyzx, r4.wwww, r2.xyzx
  add r12.xyz, r12.xyzx, -cb1[r6.x + 52].xyzx
  dp3 r15.x, r12.xyzx, cb1[r6.x + 53].xyzx
  dp3 r15.y, r12.xyzx, cb1[r6.x + 54].xyzx
  dp3 r15.z, r12.xyzx, cb1[r6.x + 55].xyzx
  utof r15.w, cb1[r6.x + 57].x
  sample_l_indexable(texturecubearray)(float,float,float,float) r6.xzw, r15.xyzw, t5.xwyz, s8, r3.w
  mul r3.z, r3.z, r14.z
  dp3 r12.x, r4.xyzx, cb1[r6.y + 53].xyzx
  dp3 r12.y, r4.xyzx, cb1[r6.y + 54].xyzx
  dp3 r12.z, r4.xyzx, cb1[r6.y + 55].xyzx
  add r14.yzw, -r13.xxyz, cb1[r6.y + 48].xxyz
  div r14.yzw, r14.yyzw, r12.xxyz
  add r13.xyz, -r13.xyzx, cb1[r6.y + 49].xyzx
  div r12.xyz, r13.xyzx, r12.xyzx
  max r12.xyz, r12.xyzx, r14.yzwy
  min r4.w, r12.y, r12.x
  min r4.w, r12.z, r4.w
  mad r2.xyz, r4.xyzx, r4.wwww, r2.xyzx
  add r2.xyz, r2.xyzx, -cb1[r6.y + 52].xyzx
  dp3 r12.x, r2.xyzx, cb1[r6.y + 53].xyzx
  dp3 r12.y, r2.xyzx, cb1[r6.y + 54].xyzx
  dp3 r12.z, r2.xyzx, cb1[r6.y + 55].xyzx
  utof r12.w, cb1[r6.y + 57].x
  sample_l_indexable(texturecubearray)(float,float,float,float) r2.xyz, r12.xyzw, t5.xyzw, s8, r3.w
  mul r2.xyz, r2.xyzx, r3.zzzz
  mad r2.xyz, r2.wwww, r6.xzwx, r2.xyzx
  sample_l_indexable(texturecube)(float,float,float,float) r4.xyz, r4.xyzx, t25.xyzw, s8, r3.w
  mul r3.yzw, r3.yyyy, r4.xxyz
  add r2.w, -r14.x, l(1.000000)
  mul r2.xyz, r2.xyzx, r14.xxxx
  mad r2.xyz, r2.wwww, r3.yzwy, r2.xyzx
  dp3 r2.w, r2.xyzx, cb1[47].xyzx
  mad r2.xyz, r2.xyzx, cb1[46].zzzz, r2.wwww
  mad r2.w, cb1[46].w, cb1[46].y, r2.z
  mul r2.xyz, r2.xywx, cb2[35].yyyy
  mad r3.yzw, r7.xxyy, l(0.000000, 0.968750, 0.968750, 4.000000), l(0.000000, 0.015625, 0.015625, 1.000000)
  sample_l_indexable(texture2d)(float,float,float,float) r3.yz, r3.yzyy, t55.zxyw, s12, l(0.000000)
  mad r4.xyz, r3.zzzz, r10.xyzx, r3.yyyy
  mul r6.xyz, r0.xxxx, r4.xyzx
  mul r1.xyz, r1.xyzx, r6.xyzx
  movc r1.xyz, r0.wwww, r1.xyzx, r6.xyzx
  mul r1.xyz, r1.xyzx, r2.xyzx
  lt r0.x, l(0.000000), r5.x
  mul r0.w, r7.x, r7.x
  mad r2.x, -r7.x, r7.x, l(1.000100)
  mul r2.y, r2.x, r2.x
  div r0.w, r0.w, r2.x
  div r0.w, -r0.w, r7.y
  mul r0.w, r0.w, l(1.442695)
  exp r0.w, r0.w
  mul r0.w, r0.w, l(4.000000)
  div r0.w, r0.w, r2.y
  add r0.w, r0.w, l(1.000000)
  div r0.w, r0.w, r3.w
  mul r2.xyz, r4.xyzx, r0.wwww
  mul r2.xyz, r0.zzzz, r2.xyzx
  mul r2.xyz, r5.yzwy, r2.xyzx
  mad r2.xyz, r2.xyzx, r5.xxxx, -r1.xyzx
  mad r2.xyz, r5.xxxx, r2.xyzx, r1.xyzx
  movc r0.xzw, r0.xxxx, r2.xxyz, r1.xxyz
  mad r11.xyz, r5.yzwy, r1.wwww, r11.xyzx
  add r1.x, r0.y, r3.x
  mad r0.xzw, cb5[60].xxxx, r0.xxzw, r8.xxyz
  add r8.xyz, r9.xyzx, r0.xzwx
  dp3 r0.x, r9.xyzx, l(0.212600, 0.715200, 0.072200, 0.000000)
  add r0.y, r0.x, r1.x
endif 
mul o0.xyz, r11.xyzx, cb2[35].xxxx
mul o1.xyz, r8.xyzx, cb2[35].xxxx
mul o0.w, r0.y, cb2[35].x
mov o1.w, l(1.000000)
ret 
// Approximately 689 instruction slots used
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/