Shader "ArmNomads/Standard URP"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_HColor ("Highlight Color", Color) = (0.785,0.785,0.785,1.0)
		_SColor ("Shadow Color", Color) = (0.195,0.195,0.195,1.0)

		_RampThreshold ("Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("Ramp Smoothing", Range(0.01,1)) = 0.1

		[Toggle(VERTEX_COLOR)] _VertexColor("Vertex Color", Int) = 0

		[Toggle(EMISSION)] _Emission("Emission", Int) = 0
		[HideInInspector] _EmissionMap("Emission Map", 2D) = "white" {}
		[HideInInspector][HDR] _EmissionColor("Color", Color) = (0,0,0,1)


		[Toggle(SPECULAR)] _Specular("Specular", Int) = 0
		[Toggle(SPECULAR_STYLIZED)][HideInInspector] _SpecularStylized("Specular Stylized", Int) = 0
		[Toggle(SPECULAR_CRISP)][HideInInspector] _SpecularCrisp("Specular Crisp", Int) = 0
		[HideInInspector][HDR] _SpecularColor("Color", Color) = (1,1,1,1)
		[HideInInspector] _SpecularRoughness("Roughness", Range(0,1)) = 0
		[HideInInspector] _SpecularToonSize("Size", Range(0,1)) = 0
		[HideInInspector] _SpecularToonSmoothness("Smoothing", Range(0,1)) = 0
		[HideInInspector] _SpecGlossMap("Specular Texture", 2D) = "white" {}

		[Toggle(NORMAL_MAP)] _NormalMap("Normal Map", Int) = 0
		[HideInInspector][Normal]_NormalMapTex("Normal Map Texture", 2D) = "" {}
		[HideInInspector] _NormalSmoothing("Normal Smoothing", Range(0,1)) = 0

		[Toggle(RIM_LIGHTING)] _RimLighting("Rim Lighting", Int) = 0
		[HideInInspector][HDR] _RimColor("Color", Color) = (1,1,1,1)
		[HideInInspector] _RimMin("Min", Range(0,1)) = 0
		[HideInInspector] _RimMax("Max", Range(0,1)) = 0
		[HideInInspector][Toggle(RIM_LIGHT_BASED)] _LightBased("Light Based", Float) = 0


		[Toggle(GRADIENT)] _Gradient("Gradient", Int) = 0
		[HideInInspector] _GradPos("Position", Float) = 0
		[HideInInspector] _GradSize("Size", Float) = 1
		[HideInInspector] _GradTopColor("Top Color", Color) = (1,1,1,1)
		[HideInInspector] _GradBottomColor("Bottom Color", Color) = (1,1,1,1)

		[Toggle(OVERLAY_TEXTURE)] _OverlayTexture("Overlay Texture", Int) = 0
		[HideInInspector][Toggle(OVERLAY_PROJECTION)] _OverlayProj("Overlay Projection", Int) = 0
		[HideInInspector] _ProjAngle("Projection Angle", Vector) = (0,0,0,0)
		[HideInInspector] _ProjScaleOffset("Scale and Offset", Vector) = (1,1,0,0)
		[HideInInspector] _OverlayTint("Tint", Color) = (1,1,1,1)
		[HideInInspector] _OverlayTex ("Texture", 2D) = "black" {}

		[Toggle(WORLD_SPACE_UV)] _WorldSpaceUV("World Space UV", Int) = 0
		[HideInInspector] _TriBlendOffset("Blend Offset", Range(0,0.5)) = 0
		[HideInInspector] _TriBlendExp("Blend Exponent", Range(1, 8)) = 2

		[Toggle(PLANE_CLIPPING)] _PlaneClipping("Plane Clipping", Int) = 0
		[HideInInspector]_PlanePosition("Plane Position", Vector) = (0,0,0,0)
		[HideInInspector]_PlaneNormal("Plane Normal", Vector) = (0,0,1,0)
		[HideInInspector][Toggle]_ClipSectionEmmisive("Emmisive", Float) = 0
		[HideInInspector]_ClipSectionColor("Clip Section Color", Color) = (1,1,1,0)

		[Toggle(DISPLACEMENT)] _Displacement("Displacement", Int) = 0
		[HideInInspector] _DisplaceMap("Disp. Map", 2D) = "black" {}
		[HideInInspector] _DisplaceHeight("Height", Float) = 0

		[Enum(UnityEngine.Rendering.CullMode)] _Culling ("Culling", Int) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1
	}

	SubShader
	{
		Name "ForwardLit"
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "UniversalMaterialType" = "Lit" }
		LOD 100
		Cull [_Culling]
		ZTest [_ZTest]
		ZWrite [_ZWrite]

		Pass
		{

			Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM

			#include "ANStandardInput.hlsl"
			#include "ANStandardURP.hlsl"

			#pragma vertex Vertex
			#pragma fragment Fragment

			#pragma multi_compile_fog

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile_fragment _ _SHADOWS_SOFT

			#pragma shader_feature_local VERTEX_COLOR
			#pragma shader_feature_local EMISSION
			#pragma shader_feature_local SPECULAR
			#pragma shader_feature_local SPECULAR_STYLIZED
			#pragma shader_feature_local SPECULAR_CRISP
			#pragma shader_feature_local NORMAL_MAP
			#pragma shader_feature_local RIM_LIGHTING
			#pragma shader_feature_local RIM_LIGHT_BASED
			#pragma shader_feature_local WORLD_SPACE_UV
			#pragma shader_feature_local OVERLAY_TEXTURE
			#pragma shader_feature_local OVERLAY_PROJECTION
			#pragma shader_feature_local GRADIENT
			#pragma shader_feature_local PLANE_CLIPPING
			#pragma shader_feature_local DISPLACEMENT

			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}

			ZWrite On
            ZTest LEqual
            ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			#include "ANStandardInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

			#pragma shader_feature_local EMISSION
			#pragma shader_feature_local SPECULAR
			#pragma shader_feature_local SPECULAR_STYLIZED
			#pragma shader_feature_local SPECULAR_CRISP
			#pragma shader_feature_local NORMAL_MAP
			#pragma shader_feature_local RIM_LIGHTING
			#pragma shader_feature_local RIM_LIGHT_BASED
			#pragma shader_feature_local WORLD_SPACE_UV
			#pragma shader_feature_local OVERLAY_TEXTURE
			#pragma shader_feature_local OVERLAY_PROJECTION
			#pragma shader_feature_local GRADIENT
			#pragma shader_feature_local PLANE_CLIPPING
			#pragma shader_feature_local DISPLACEMENT

			// Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
			// For Directional lights, _LightDirection is used when applying shadow Normal Bias.
			// For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
			float3 _LightDirection;
			float3 _LightPosition;

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
#if PLANE_CLIPPING
				float3 positionWS : TEXCOORD0;
#endif
			};

			float4 GetShadowPositionHClip(Attributes input)
			{
				float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

				float3 lightDirectionWS = _LightDirection;

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
				positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
				positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				return positionCS;
			}

			Varyings ShadowPassVertex(Attributes input)
			{
				Varyings output;
#if PLANE_CLIPPING
				output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
#endif
				output.positionCS = GetShadowPositionHClip(input);
				return output;
			}

			half4 ShadowPassFragment(Varyings input) : SV_TARGET
			{
#if PLANE_CLIPPING
				clip(dot((_PlanePosition - input.positionWS), _PlaneNormal));
#endif
				return 0;
			}
			ENDHLSL
		}
	}

	CustomEditor "ArmNomads.Shaders.ANStandardShaderGUI"
}
