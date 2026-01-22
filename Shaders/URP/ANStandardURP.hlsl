#ifndef AN_STANDARD_INCLUDED
#define AN_STANDARD_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define EPSILON 1e-4f

inline real3 GetObjectScale()
{
	// Length of basis vectors in object->world matrix (handles non-uniform scale).
	real3 scale;
	scale.x = length(unity_ObjectToWorld._m00_m10_m20);
	scale.y = length(unity_ObjectToWorld._m01_m11_m21);
	scale.z = length(unity_ObjectToWorld._m02_m12_m22);
	return max(scale, EPSILON);
}

struct Attributes
{
	real4 positionOS : POSITION;
	real2 uv : TEXCOORD0;
	real3 normalOS : NORMAL;
	half3 color : COLOR0;
#if DISPLACEMENT || NORMAL_MAP
	real3 tangentOS : TANGENT;
#endif
};

struct Varyings
{
	real4 pos : SV_POSITION;
#if SPECULAR || RIM_LIGHTING || OVERLAY_PROJECTION || PLANE_CLIPPING || (WORLD_SPACE_UV || LOCAL_SPACE_UV) || ((DISPLACEMENT || NORMAL_MAP) && (WORLD_SPACE_UV || LOCAL_SPACE_UV))
	real3 normal : NORMAL;
#endif
	half3 color : COLOR2;
	real2 uv : TEXCOORD0;
	real4 shadowCoord : TEXCOORD2;
#if WORLD_SPACE_UV || LOCAL_SPACE_UV
	real3 triWeights : TEXCOORD3;
#endif
	real4 worldPosAndFogFactor : TEXCOORD4;
#if LOCAL_SPACE_UV
	real3 triPosOS : TEXCOORD6;
	real3 triNormalOS : TEXCOORD7;
#endif
#if DISPLACEMENT || NORMAL_MAP
	real3x3 TBN : TEXCOORD5;
#else
	real3 ambient : COLOR1;
	real3 ramp : COLOR0;
#endif
};

#if SPECULAR
	inline real GGX(real NdotH, real roughness)
	{
		real a2 = roughness * roughness;
		real d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
		return INV_PI * a2 / (d * d + EPSILON);
	}

	inline real CalculateSpecular(real3 lightDir, real3 viewDir, real3 normal, real specularMap)
	{
		real3 realDir = SafeNormalize(lightDir + viewDir);
		real nh = saturate(dot(normal, realDir));

		#if SPECULAR_STYLIZED || SPECULAR_CRISP
			real specSize = 1 - (_SpecularToonSize * specularMap);
			nh = nh * (1.0 / (1.0 - specSize)) - (specSize / (1.0 - specSize));
			#if defined(SPECULAR_CRISP)
				real specSmoothness = fwidth(nh);
			#else
				real specSmoothness = _SpecularToonSmoothness;
			#endif
			real spec = smoothstep(0, specSmoothness, nh);
		#else
			real specularRoughness = max(0.00001, _SpecularRoughness)* specularMap;
			real roughness = specularRoughness * specularRoughness;
			real spec = GGX(nh, saturate(roughness));
			spec *= PI * 0.05;
			#if UNITY_COLORSPACE_GAMMA
				spec = max(0, sqrt(max(1e-4h, spec)));
				real surfaceReduction = 1.0 - 0.28 * roughness * specularRoughness;
			#else
				real surfaceReduction = 1.0 / (roughness * roughness + 1.0);
			#endif
			spec *= surfaceReduction;
		#endif
		return max(0, spec);
	}
#endif

#if GRADIENT
	inline half4 GetGradientColor(real worldPosY)
	{
		real t = saturate((worldPosY - _GradPos + _GradSize / 2) / _GradSize);
		return lerp(_GradBottomColor, _GradTopColor, t);
	}
#endif

#if WORLD_SPACE_UV || LOCAL_SPACE_UV
	inline half3 GetTriPlanarWeights(half3 normal)
	{
		#if LOCAL_SPACE_UV
			// Shader Graph-style: pure exponent blending, no offset.
			// Use large exponent values (50-200) for "one seam" look.
			half3 triWeights = pow(abs(normal), _TriBlendExp);
		#else
			// World space: offset + exponent (original behavior).
			half3 triWeights = saturate(abs(normal) - _TriBlendOffset);
			triWeights = pow(triWeights, _TriBlendExp);
		#endif
		return triWeights / (triWeights.x + triWeights.y + triWeights.z);
	}

	inline half4 TriplanarSample(sampler2D tex, half3 weights, real3 pos, real4 texST)
	{
		half4 colorXOZ = tex2D(tex, pos.xz * texST.xy + texST.zw) * weights.y;
		half4 colorXOY = tex2D(tex, pos.xy * texST.xy + texST.zw) * weights.z;
		half4 colorZOY = tex2D(tex, pos.zy * texST.xy + texST.zw) * weights.x;
		return colorXOZ + colorXOY + colorZOY;
	}

	inline half4 TriplanarSampleLod(sampler2D tex, half3 weights, real3 pos, real4 texST, half lod)
	{
		half4 colorXOZ = tex2Dlod(tex, half4(pos.xz * texST.xy + texST.zw, 0.0, lod)) * weights.y;
		half4 colorXOY = tex2Dlod(tex, half4(pos.xy * texST.xy + texST.zw, 0.0, lod)) * weights.z;
		half4 colorZOY = tex2Dlod(tex, half4(pos.zy * texST.xy + texST.zw, 0.0, lod)) * weights.x;
		return colorXOZ + colorXOY + colorZOY;
	}

	inline half3 GetTriplanarNormal(sampler2D normalMap, half3 weights, half3 wNormal, real3 wPos, real4 texST)
	{
		real2 uvZY = wPos.zy * texST.xy + texST.zw;
		real2 uvXZ = wPos.xz * texST.xy + texST.zw;
		real2 uvXY = wPos.xy * texST.xy + texST.zw;

		half3 tNormalZY = UnpackNormal(tex2D(normalMap, uvZY));
		half3 tNormalXZ = UnpackNormal(tex2D(normalMap, uvXZ));
		half3 tNormalXY = UnpackNormal(tex2D(normalMap, uvXY));

		half3 normalZY = half3(0, tNormalZY[1], tNormalZY[0]);
		half3 normalXZ = half3(tNormalXZ[0], 0, tNormalXZ[1]);
		half3 normalXY = half3(tNormalXY[0], tNormalXY[1], 0);

		return normalize(normalZY * weights.x +
							normalXZ * weights.y +
							normalXY * weights.z +
							wNormal);
	}
#endif

#if WORLD_SPACE_UV || LOCAL_SPACE_UV
	inline real3 GetTriplanarPos(Varyings i)
	{
		#if LOCAL_SPACE_UV
			return i.triPosOS;
		#else
			return i.worldPosAndFogFactor.xyz;
		#endif
	}

	inline half3 GetTriplanarBaseNormal(Varyings i)
	{
		#if LOCAL_SPACE_UV
			return normalize(i.triNormalOS);
		#else
			return normalize(i.normal);
		#endif
	}

	// Get triplanar weights - for LOCAL_SPACE_UV compute per-pixel for sharp results
	inline half3 GetTriplanarWeightsFragment(Varyings i)
	{
		#if LOCAL_SPACE_UV
			// Use float precision to handle high exponent values without precision loss.
			float3 n;
			if (_LocalTriplanarWorldNormal > 0.5)
			{
				// World-space normal for blending (Shader Graph style) - cleaner at high blend values
				n = abs(normalize(i.normal));
			}
			else
			{
				// Object-space normal for blending (fully local) - texture blending rotates with object
				n = abs(normalize(i.triNormalOS));
			}
			// Shader Graph style: pow then normalize by dot product
			float3 w = pow(n, _TriBlendExp);
			w /= dot(w, 1.0);
			return (half3)w;
		#else
			// World space uses precomputed weights from vertex shader.
			return i.triWeights;
		#endif
	}
#endif

#if DISPLACEMENT
	inline half3 GetReconstructedNormal(sampler2D heightMap, real4 texelSize, real2 uv, real maxHeight, real4 texST)
	{
		real4 p;
		real3 n;
		p[0] = tex2Dlod(heightMap, real4(uv * texST.xy + texST.zw + real2(texelSize.x, 0.0), 0.0, 0.0)).r;
		p[1] = tex2Dlod(heightMap, real4(uv * texST.xy + texST.zw + real2(-texelSize.x, 0.0), 0.0, 0.0)).r;
		p[2] = tex2Dlod(heightMap, real4(uv * texST.xy + texST.zw + real2(0.0, texelSize.y), 0.0, 0.0)).r;
		p[3] = tex2Dlod(heightMap, real4(uv * texST.xy + texST.zw + real2(0.0, -texelSize.y), 0.0, 0.0)).r;
		p *= maxHeight;
		n.x = p[1] - p[0];
		n.y = p[3] - p[2];
		n.z = (2.0 / texelSize.z);

		return normalize(n);
	}

	inline half3 ReconstructNormalTriplanar(sampler2D heightMap, real4 texelSize, half3 weights, half3 wNormal, real3 wPos, real maxHeight, real4 texST)
	{
		half3 tNormalZY = GetReconstructedNormal(heightMap, texelSize, wPos.zy, maxHeight, texST);
		half3 tNormalXZ = GetReconstructedNormal(heightMap, texelSize, wPos.xz, maxHeight, texST);
		half3 tNormalXY = GetReconstructedNormal(heightMap, texelSize, wPos.xy, maxHeight, texST);

		half3 normalZY = half3(0, tNormalZY[1], tNormalZY[0]);
		half3 normalXZ = half3(tNormalXZ[0], 0, tNormalXZ[1]);
		half3 normalXY = half3(tNormalXY[0], tNormalXY[1], 0);

		return normalize(normalZY * weights.x +
							normalXZ * weights.y +
							normalXY * weights.z +
							wNormal);
	}
#endif

inline half3 GetLightingRamp(half3 normal)
{
	half ndl = dot(normal, _MainLightPosition.xyz) * 0.5 + 0.5;
	return smoothstep(_RampThreshold - _RampSmooth * 0.5, _RampThreshold + _RampSmooth * 0.5, ndl);
}

//check UV
inline half3 GetLuminance(half3 ramp, real2 uv)
{
	_SColor = lerp(_HColor, _SColor, _SColor.a);
	return lerp(_SColor.rgb, _HColor.rgb, ramp);
}

inline half4 CalculateShading(half3 diffuse, Varyings i, half facing)
{
	half3 ramp = 0.0, ambient = 0.0, emission = 0.0;
	half3 normal;
	#if SPECULAR || RIM_LIGHTING
		half3 viewDir = SafeNormalize(_WorldSpaceCameraPos.xyz - i.worldPosAndFogFactor.xyz);
	#endif

	#if DISPLACEMENT || NORMAL_MAP
		#if WORLD_SPACE_UV || LOCAL_SPACE_UV
			real3 triPos = GetTriplanarPos(i);
			half3 triBaseNormal = GetTriplanarBaseNormal(i);
			half3 triWeights = GetTriplanarWeightsFragment(i);
			#if DISPLACEMENT
				half3 triNormal = ReconstructNormalTriplanar(_DisplaceMap, _DisplaceMap_TexelSize, triWeights, triBaseNormal, triPos, _DisplaceHeight, _MainTex_ST);
				#if LOCAL_SPACE_UV
					normal = normalize(TransformObjectToWorldNormal(triNormal));
				#else
					normal = triNormal;
				#endif
			#else
				half3 triNormal = GetTriplanarNormal(_NormalMapTex, triWeights, triBaseNormal, triPos, _MainTex_ST);
				#if LOCAL_SPACE_UV
					normal = normalize(TransformObjectToWorldNormal(triNormal));
					normal = normalize(lerp(normal, normalize(i.normal), _NormalSmoothing));
				#else
					normal = lerp(triNormal, i.normal, _NormalSmoothing);
				#endif
			#endif
		#else
			i.TBN = half3x3(normalize(i.TBN[0]), normalize(i.TBN[1]), normalize(i.TBN[2]));
			i.TBN = transpose(i.TBN);
			half3 tangentSpaceNormal;
			#if DISPLACEMENT
				tangentSpaceNormal = GetReconstructedNormal(_DisplaceMap, _DisplaceMap_TexelSize, i.uv, _DisplaceHeight, _MainTex_ST);
			#else
				tangentSpaceNormal = UnpackNormal(tex2D(_NormalMapTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw));
				tangentSpaceNormal = lerp(tangentSpaceNormal, half3(0,0,1), _NormalSmoothing);
			#endif
			normal = mul(i.TBN, tangentSpaceNormal);
		#endif
		ramp = GetLightingRamp(normal);
		ambient = SampleSHVertex(normal);
	#else
		ramp = i.ramp;
		ambient = i.ambient;
		#if SPECULAR || RIM_LIGHTING || PLANE_CLIPPING
			normal = normalize(i.normal);
		#endif
	#endif

	#if PLANE_CLIPPING
		_PlaneNormal = normalize(_PlaneNormal);
		half blend = lerp(1, 0, step(0.5,facing)) * _ClipSectionColor.a;
		diffuse = lerp(diffuse, _ClipSectionColor.rgb, blend);
		diffuse *= step(0,_ClipSectionEmmisive);
		emission = lerp(emission, _ClipSectionColor.rgb, blend * _ClipSectionEmmisive);
		normal = lerp(_PlaneNormal, normal, step(0.5, facing));
		ramp = lerp(GetLightingRamp(normal), ramp, step(0.5,facing));
		ambient = lerp(SampleSHVertex(normal), ambient, step(0.5, facing));
	#endif

	half3 lum = GetLuminance(ramp, i.uv);
	half shadow = MainLightShadow(TransformWorldToShadowCoord(i.worldPosAndFogFactor.xyz), i.worldPosAndFogFactor.xyz,unity_ProbesOcclusion,_MainLightOcclusionProbes);
	lum = lerp(_SColor.rgb, lum, shadow);
	half4 col = half4(ambient * diffuse, 1);
	col.rgb += diffuse * _MainLightColor.rgb * lum;
	#if !GRADIENT
		col.rgb *= _Color.rgb;
	#endif

	#if RIM_LIGHTING
		half3 rimMask = half3(1.0, 1.0, 1.0);
		#if RIM_LIGHT_BASED
			rimMask = ramp * _MainLightColor.rgb;
		#endif
		half ndv = 1.0 - max(0, dot(viewDir, normal));
		half rim = smoothstep(_RimMin, _RimMax, ndv);
		col.rgb += rimMask.rgb * rim * _RimColor.rgb;
	#endif

	#if SPECULAR
		#if WORLD_SPACE_UV || LOCAL_SPACE_UV
			half specularMap = TriplanarSample(_SpecGlossMap, GetTriplanarWeightsFragment(i), GetTriplanarPos(i), _MainTex_ST).r;
		#else
			half specularMap = tex2D(_SpecGlossMap, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).r;
		#endif
		half spec = CalculateSpecular(_MainLightPosition.xyz, viewDir, normal, specularMap);
		half ndl = max(0.0, dot(normal, _MainLightPosition.xyz));
		col.rgb += spec * specularMap* shadow* ndl * _MainLightColor.rgb* _SpecularColor.rgb;
	#endif

	#if EMISSION
		emission += _EmissionColor;
		#if WORLD_SPACE_UV || LOCAL_SPACE_UV
			half3 emissionMap = TriplanarSample(_EmissionMap, GetTriplanarWeightsFragment(i), GetTriplanarPos(i), _EmissionMap_ST).rgb;
		#else
			half3 emissionMap = tex2D(_EmissionMap, i.uv * _EmissionMap_ST.xy + _EmissionMap_ST.zw).rgb;
		#endif
		emission *= emissionMap;
	#endif
	col.rgb += emission;
	return col;
}

Varyings Vertex(Attributes v)
{
	Varyings o;

	// Normals are computed from the original mesh normal (position changes below don't affect it).
	half3 normalWS = TransformObjectToWorldNormal(v.normalOS);

	#if LOCAL_SPACE_UV
		real3 objScale = GetObjectScale();
	#endif

	#if WORLD_SPACE_UV || LOCAL_SPACE_UV
		half3 triNormalForWeights = normalWS;
		#if LOCAL_SPACE_UV
			// For local/object triplanar we want weights that match the *scaled* surface.
			// Using normalOS directly breaks on non-uniform scale; compensate by dividing by scale.
			triNormalForWeights = normalize(v.normalOS / objScale);
		#endif
		o.triWeights = GetTriPlanarWeights(triNormalForWeights);
	#endif

	o.color = v.color;
	o.uv = v.uv;

	#if DISPLACEMENT || NORMAL_MAP
		half3 worldTangent = TransformObjectToWorldDir(v.tangentOS);
		half3 worldNormal = TransformObjectToWorldDir(v.normalOS);
		half3 worldBiTangent = cross(worldTangent, worldNormal);
		o.TBN = half3x3(worldTangent, worldBiTangent, worldNormal);
		#if DISPLACEMENT
			#if WORLD_SPACE_UV || LOCAL_SPACE_UV
				real3 triPos = TransformObjectToWorld(v.positionOS.xyz);
				#if LOCAL_SPACE_UV
					// Use "object axes, world units" so tiling doesn't change with transform scale.
					triPos = v.positionOS.xyz * objScale;
				#endif
				real displace = TriplanarSampleLod(_DisplaceMap, o.triWeights, triPos, _MainTex_ST, 0.0).r;
			#else
				real displace = tex2Dlod(_DisplaceMap, half4(v.uv * _MainTex_ST.xy + _MainTex_ST.zw, 0.0, 0.0)).r;
			#endif
			real3 worldPosPre = TransformObjectToWorld(v.positionOS.xyz).xyz;
			v.positionOS.xyz = TransformWorldToObject(worldPosPre + worldNormal * displace * _DisplaceHeight);
		#endif
	#else
		o.ambient = SampleSHVertex(normalWS);
		o.ramp = GetLightingRamp(normalWS);
	#endif

	// World position used by lighting/fog/etc. (computed after displacement, if any).
	o.worldPosAndFogFactor.xyz = TransformObjectToWorld(v.positionOS.xyz).xyz;

	#if LOCAL_SPACE_UV
		// Store scaled position so sampling is independent of transform scale.
		o.triPosOS = v.positionOS.xyz * objScale;
		// Keep base normal in true object space so we can safely TransformObjectToWorldNormal(...) later.
		o.triNormalOS = normalize(v.normalOS);
	#endif

	#if SPECULAR || RIM_LIGHTING || OVERLAY_PROJECTION || PLANE_CLIPPING || (WORLD_SPACE_UV || LOCAL_SPACE_UV) || ((DISPLACEMENT || NORMAL_MAP) && (WORLD_SPACE_UV || LOCAL_SPACE_UV))
			o.normal = normalWS;
	#endif
	o.pos = TransformObjectToHClip(v.positionOS.xyz);
	o.worldPosAndFogFactor.w = o.pos.z;
	o.shadowCoord = TransformWorldToShadowCoord(o.worldPosAndFogFactor.xyz);
	return o;
}

#if OVERLAY_TEXTURE && OVERLAY_PROJECTION
half3 GetProjectionPlaneNormal()
{
	_ProjAngle *= PI;
	return real3(cos(_ProjAngle.x) * cos(_ProjAngle.y), sin(_ProjAngle.y), sin(_ProjAngle.x) * cos(_ProjAngle.y));
}

half3x3 GetTransformationMatrix(half3 normal)
{
	half3 t = normalize(half3(normal.z, 0, -normal.x));
	half3 b = cross(normal,t);
	return half3x3(t, b, normal);
}
#endif

half4 Fragment(Varyings i, half facing : VFACE) : SV_Target
{
	#if PLANE_CLIPPING
		clip(dot((_PlanePosition - i.worldPosAndFogFactor.xyz), _PlaneNormal));
	#endif

	#if WORLD_SPACE_UV || LOCAL_SPACE_UV
		half3 diffuse = TriplanarSample(_MainTex, GetTriplanarWeightsFragment(i), GetTriplanarPos(i), _MainTex_ST).rgb;
	#else
		half3 diffuse = tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
	#endif

	#if VERTEX_COLOR
		diffuse *= i.color;
	#endif

	half4 col = CalculateShading(diffuse, i, facing);

	#if OVERLAY_TEXTURE
		#if OVERLAY_PROJECTION
			half3 projPlaneNormal = GetProjectionPlaneNormal();
			half3 localPos = TransformWorldToObject(i.worldPosAndFogFactor.xyz);
			real2 uv = mul(GetTransformationMatrix(projPlaneNormal), localPos).xy / _ProjScaleOffset.xy + _ProjScaleOffset.zw + 0.5;
			half4 overlay = tex2D(_OverlayTex, uv) * step(0,dot(projPlaneNormal, i.normal));
		#elif WORLD_SPACE_UV || LOCAL_SPACE_UV
			half4 overlay = TriplanarSample(_OverlayTex, GetTriplanarWeightsFragment(i), GetTriplanarPos(i), _OverlayTex_ST);
		#else
			half4 overlay = tex2D(_OverlayTex, i.uv * _OverlayTex_ST.xy + _OverlayTex_ST.zw);
		#endif
		col.rgb = lerp(saturate(col.rgb), overlay.rgb * _OverlayTint.rgb, overlay.a * _OverlayTint.a);
	#endif

	#if GRADIENT
		half4 gradCol = GetGradientColor(i.worldPosAndFogFactor.y);
		col.rgb *= lerp(_Color, _Color * gradCol, gradCol.a);
	#endif
	col.rgb = MixFog(col.rgb, ComputeFogFactor(i.worldPosAndFogFactor.w));
	return col;
}

#endif