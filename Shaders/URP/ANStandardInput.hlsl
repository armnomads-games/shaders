#ifndef AN_STANDARD_INPUT_INCLUDED
#define AN_STANDARD_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)

sampler2D _MainTex;
real4 _MainTex_ST;

half4 _Color;
half4 _HColor;
half4 _SColor;

real _RampThreshold;
real _RampSmooth;

//EMISSION
sampler2D _EmissionMap;
real4  _EmissionMap_ST;
real4 _EmissionColor;

//SPECULAR
real _SpecularRoughness;
real4 _SpecularColor;
sampler2D _SpecGlossMap;
real _SpecularToonSize;
real _SpecularToonSmoothness;

//NORMAL_MAP
sampler2D _NormalMapTex;
real _NormalSmoothing;

//RIM_LIGHTING
real4 _RimColor;
real _RimMin;
real _RimMax;

//GRADIENT
real _GradPos;
real _GradSize;
real4 _GradTopColor;
real4 _GradBottomColor;

//WORLD_SPACE_UV / LOCAL_SPACE_UV
real _TriBlendOffset;
real _TriBlendExp;
real _LocalTriplanarWorldNormal;

//PLANE_CLIPPING
real3 _PlanePosition;
real3 _PlaneNormal;
real _ClipSectionEmmisive;
real4 _ClipSectionColor;

//OVERLAY_TEXTURE
real2 _ProjAngle;
real4 _ProjScaleOffset;
sampler2D _OverlayTex;
real4 _OverlayTex_ST;
real4 _OverlayTint;

//DISPLACEMENT
sampler2D _DisplaceMap;
real4 _DisplaceMap_TexelSize;
real _DisplaceHeight;

CBUFFER_END

#endif