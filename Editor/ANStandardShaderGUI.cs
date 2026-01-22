using UnityEditor;
using UnityEngine;

namespace ArmNomads.Shaders
{
    public class ANStandardShaderGUI : ShaderGUI
    {
        private static readonly string[] SPECULAR_TYPES = { "Standard", "Stylized", "Crisp" };
        private static bool showAdvancedTriplanar;
        private static bool clampTriplanarSharpness = true;

        private Material targetMat;

        private MaterialProperty emissionMapProp;
        private MaterialProperty emissionColorProp;
        private MaterialProperty specColorProp;
        private MaterialProperty specRoughnessProp;
        private MaterialProperty specSizeProp;
        private MaterialProperty specSmoothnessProp;
        private MaterialProperty specTextureProp;
        private MaterialProperty normalMapTexProp;
        private MaterialProperty normalSmoothingProp;
        private MaterialProperty rimColorProp;
        private MaterialProperty rimMinProp;
        private MaterialProperty rimMaxProp;
        private MaterialProperty rimLightBasedProp;
        private MaterialProperty gradientPosProp;
        private MaterialProperty gradientSizeProp;
        private MaterialProperty gradientTopColorProp;
        private MaterialProperty gradientBottomColorProp;
        private MaterialProperty triBlendOffsetProp;
        private MaterialProperty triBlendExpProp;
        private MaterialProperty localTriplanarWorldNormalProp;
        private MaterialProperty worldSpaceUVProp;
        private MaterialProperty localSpaceUVProp;
        private MaterialProperty overlayProjProp;
        private MaterialProperty projAngleProp;
        private MaterialProperty projScaleOffsetProp;
        private MaterialProperty overlayTintProp;
        private MaterialProperty overlayTexProp;
        private MaterialProperty clipPlanePosProp;
        private MaterialProperty clipPlaneNormalProp;
        private MaterialProperty clipSectionEmmisiveProp;
        private MaterialProperty clipSectionColorProp;
        private MaterialProperty displacementMapProp;
        private MaterialProperty displacementHeightProp;

        private int selectedSpecularType;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            targetMat = materialEditor.target as Material;

            emissionMapProp = FindProperty("_EmissionMap", properties);
            emissionColorProp = FindProperty("_EmissionColor", properties);

            specColorProp = FindProperty("_SpecularColor", properties);
            specRoughnessProp = FindProperty("_SpecularRoughness", properties);
            specSizeProp = FindProperty("_SpecularToonSize", properties);
            specSmoothnessProp = FindProperty("_SpecularToonSmoothness", properties);
            specTextureProp = FindProperty("_SpecGlossMap", properties);

            normalMapTexProp = FindProperty("_NormalMapTex", properties);
            normalSmoothingProp = FindProperty("_NormalSmoothing", properties);

            rimColorProp = FindProperty("_RimColor", properties);
            rimMinProp = FindProperty("_RimMin", properties);
            rimMaxProp = FindProperty("_RimMax", properties);
            rimLightBasedProp = FindProperty("_LightBased", properties);

            gradientPosProp = FindProperty("_GradPos", properties);
            gradientSizeProp = FindProperty("_GradSize", properties);
            gradientTopColorProp = FindProperty("_GradTopColor", properties);
            gradientBottomColorProp = FindProperty("_GradBottomColor", properties);

            triBlendOffsetProp = FindProperty("_TriBlendOffset", properties);
            triBlendExpProp = FindProperty("_TriBlendExp", properties);
            localTriplanarWorldNormalProp = FindProperty("_LocalTriplanarWorldNormal", properties, false);

            worldSpaceUVProp = FindProperty("_WorldSpaceUV", properties, false);
            localSpaceUVProp = FindProperty("_LocalSpaceUV", properties, false);

            overlayProjProp = FindProperty("_OverlayProj", properties);
            projAngleProp = FindProperty("_ProjAngle", properties);
            projScaleOffsetProp = FindProperty("_ProjScaleOffset", properties);
            overlayTintProp = FindProperty("_OverlayTint", properties);
            overlayTexProp = FindProperty("_OverlayTex", properties);

            clipPlanePosProp = FindProperty("_PlanePosition", properties);
            clipPlaneNormalProp = FindProperty("_PlaneNormal", properties);
            clipSectionEmmisiveProp = FindProperty("_ClipSectionEmmisive", properties);
            clipSectionColorProp = FindProperty("_ClipSectionColor", properties);

            displacementMapProp = FindProperty("_DisplaceMap", properties);
            displacementHeightProp = FindProperty("_DisplaceHeight", properties);

            foreach (var property in properties)
            {
                if (((int)property.propertyFlags & (int)UnityEngine.Rendering.ShaderPropertyFlags.HideInInspector) > 0)
                    continue;
                if (property.name.Equals("_VertexColor"))
                {
                    DrawVertexColorProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Emission"))
                {
                    DrawEmissionProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Specular"))
                {
                    DrawSpecularProperties(property, materialEditor);
                }
                else if (property.name.Equals("_NormalMap"))
                {
                    DrawNormalMapProperties(property, materialEditor);
                }
                else if (property.name.Equals("_WorldSpaceUV"))
                {
                    DrawWorldSpaceUVProperties(property, materialEditor);
                }
                else if (property.name.Equals("_LocalSpaceUV"))
                {
                    DrawLocalSpaceUVProperties(property, materialEditor);
                }
                else if (property.name.Equals("_OverlayTexture"))
                {
                    DrawOverlayTextureProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Gradient"))
                {
                    DrawGradientProperties(property, materialEditor);
                }
                else if (property.name.Equals("_PlaneClipping"))
                {
                    DrawPlaneClippingProperties(property, materialEditor);
                }
                else if (property.name.Equals("_Displacement"))
                {
                    DrawDisplacementProperties(property, materialEditor);
                }
                else if (property.name.Equals("_RimLighting"))
                {
                    DrawRimLightingProperties(property, materialEditor);
                }
                else
                {
                    materialEditor.ShaderProperty(property, property.displayName);
                }
            }
            EditorGUILayout.Space();
            materialEditor.EnableInstancingField();
            materialEditor.RenderQueueField();
        }


        private void DrawWorldSpaceUVProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(
                    toggleProp,
                    "WORLD_SPACE_UV",
                    "Enables world-space triplanar mapping (world position + world normal).\n\nUseful for making textures ignore mesh UVs and stay consistent across different meshes.\nUses offset + exponent blending (more control, legacy behavior)."
                );

                // Mutually exclusive with Local Space UV.
                if (toggleProp.floatValue > 0)
                    DisableUvMode(localSpaceUVProp, "LOCAL_SPACE_UV");

                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                DrawTriplanarControls(materialEditor);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawLocalSpaceUVProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(
                    toggleProp,
                    "LOCAL_SPACE_UV",
                    "Enables local/object-space triplanar mapping (Shader Graph-style).\n\nTexture sticks to the object when it moves/rotates/scales.\nUses pure exponent blending (no offset) for clean 'one seam' look at high values."
                );

                // Mutually exclusive with World Space UV.
                if (toggleProp.floatValue > 0)
                    DisableUvMode(worldSpaceUVProp, "WORLD_SPACE_UV");

                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                DrawLocalTriplanarControls(materialEditor);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawLocalTriplanarControls(MaterialEditor materialEditor)
        {
            bool useWorldNormal = true;

            // Toggle for world-space vs object-space normal blending
            if (localTriplanarWorldNormalProp != null)
            {
                useWorldNormal = localTriplanarWorldNormalProp.floatValue > 0.5f;
                EditorGUI.BeginChangeCheck();
                useWorldNormal = EditorGUILayout.ToggleLeft(
                    new GUIContent(
                        "Use World Normal for Blending",
                        "When ON (recommended): Uses world-space normal for blend weights.\n" +
                        "Cleaner results at high Blend values (Shader Graph-style).\n\n" +
                        "When OFF: Uses object-space normal for blend weights.\n" +
                        "Texture blending also rotates with the object (fully local).\n" +
                        "Shows Sharpness slider + Advanced controls."
                    ),
                    useWorldNormal
                );
                if (EditorGUI.EndChangeCheck())
                {
                    localTriplanarWorldNormalProp.floatValue = useWorldNormal ? 1f : 0f;
                }
            }

            if (useWorldNormal)
            {
                // World normal mode: Shader Graph-style, pure exponent, no offset.
                // Show a single "Triplanar Blend" field.
                float blendValue = triBlendExpProp.floatValue;

                EditorGUI.BeginChangeCheck();
                blendValue = EditorGUILayout.FloatField(
                    new GUIContent(
                        "Triplanar Blend",
                        "Shader Graph-style blend exponent.\n\n" +
                        "1 = very soft blending\n" +
                        "8 = typical sharp\n" +
                        "50–200 = very sharp, only axis-switch seam visible\n\n" +
                        "Uses pure exponent blending (no offset)."
                    ),
                    blendValue
                );
                if (EditorGUI.EndChangeCheck())
                {
                    triBlendExpProp.floatValue = Mathf.Max(0.0001f, blendValue);
                    // Ensure offset is 0 for world normal mode (Shader Graph style).
                    triBlendOffsetProp.floatValue = 0f;
                }
            }
            else
            {
                // Object-space normal mode: use the full controls (sharpness + advanced offset/exponent)
                DrawTriplanarControls(materialEditor);
            }
        }

        private void DrawTriplanarControls(MaterialEditor materialEditor)
        {
            // Default UX: one "Sharpness" slider that drives both internal properties.
            float sharpnessRaw = GetTriplanarSharpnessRaw(triBlendOffsetProp.floatValue, triBlendExpProp.floatValue);

            clampTriplanarSharpness = EditorGUILayout.ToggleLeft(
                new GUIContent(
                    "Simple Mode (0–1)",
                    "When enabled: shows a simple Sharpness slider (0–1).\n\n" +
                    "When disabled: shows Triplanar Blend (Shader Graph-style).\n" +
                    "Use large values (50–200) to get the 'one seam' look."
                ),
                clampTriplanarSharpness
            );

            if (clampTriplanarSharpness)
            {
                float sharpness01 = Mathf.Clamp01(sharpnessRaw);
                EditorGUI.BeginChangeCheck();
                sharpness01 = EditorGUILayout.Slider(
                    new GUIContent(
                        "Triplanar Sharpness",
                        "Controls how strongly one projection axis dominates.\n\nLow: smoother blending (fewer seams, more mixing).\nHigh: crisper projection (less mixing)."
                    ),
                    sharpness01,
                    0f,
                    1f
                );
                if (EditorGUI.EndChangeCheck())
                    SetTriplanarFromSharpness(sharpness01, clamp: true);
            }
            else
            {
                // For unclamped, we show "Triplanar Blend" which is the direct exponent (Shader Graph style).
                // This lets users type large values (e.g. 194) to get the "one seam" look.
                float blendValue = GetTriplanarBlendValue();

                EditorGUI.BeginChangeCheck();
                blendValue = EditorGUILayout.FloatField(
                    new GUIContent(
                        "Triplanar Blend",
                        "Shader Graph-style blend exponent.\n\n" +
                        "1 = soft blending\n" +
                        "8 = typical sharp (same as clamped sharpness=1)\n" +
                        ">50 = very sharp, only axis-switch seam visible\n\n" +
                        "Internally sets Blend Offset = 0 and uses this as Blend Exponent."
                    ),
                    blendValue
                );
                if (EditorGUI.EndChangeCheck())
                    SetTriplanarFromBlendValue(blendValue);
            }

            // Advanced override: direct control for fine-tuning / legacy material values.
            showAdvancedTriplanar = EditorGUILayout.Foldout(
                showAdvancedTriplanar,
                new GUIContent("Advanced", "Show the raw triplanar parameters (Blend Offset / Blend Exponent) for fine-tuning or legacy materials."),
                true
            );
            if (!showAdvancedTriplanar)
                return;

            ++EditorGUI.indentLevel;
            materialEditor.ShaderProperty(
                triBlendOffsetProp,
                new GUIContent(
                    triBlendOffsetProp.displayName,
                    "Cuts off small axis contributions before normalization.\nHigher values reduce blending and make transitions crisper."
                )
            );
            materialEditor.ShaderProperty(
                triBlendExpProp,
                new GUIContent(
                    triBlendExpProp.displayName,
                    "Shapes the blend curve after offset.\nHigher values make the dominant axis win more strongly (sharper triplanar)."
                )
            );
            --EditorGUI.indentLevel;
        }

        private float GetTriplanarSharpnessRaw(float blendOffset, float blendExponent)
        {
            // Inverse of SetTriplanarFromSharpness (approximately). Can be outside [0..1].
            float offsetPart = blendOffset / 0.5f;
            float expPart = (blendExponent - 1f) / 7f;
            return (offsetPart + expPart) * 0.5f;
        }

        private void SetTriplanarFromSharpness(float sharpness, bool clamp)
        {
            if (clamp)
                sharpness = Mathf.Clamp01(sharpness);

            // Map "sharpness" to internal properties. When unclamped this extrapolates beyond the usual ranges.
            // Offset provides a cutoff (less blending), exponent shapes the curve (more dominance).
            triBlendOffsetProp.floatValue = 0.5f * sharpness;
            triBlendExpProp.floatValue = Mathf.Max(0.0001f, 1f + 7f * sharpness);
        }

        private float GetTriplanarBlendValue()
        {
            // For unclamped "Shader Graph style" mode, we use the exponent directly.
            return triBlendExpProp.floatValue;
        }

        private void SetTriplanarFromBlendValue(float blendValue)
        {
            // Shader Graph triplanar: weights = pow(abs(N), blend); weights /= sum(weights);
            // No offset, exponent is the blend value directly.
            triBlendOffsetProp.floatValue = 0f;
            triBlendExpProp.floatValue = Mathf.Max(0.0001f, blendValue);
        }

        private void DisableUvMode(MaterialProperty modeProp, string keyword)
        {
            if (modeProp == null)
                return;
            modeProp.floatValue = 0;
            targetMat.DisableKeyword(keyword);
        }

        private void DrawRimLightingProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "RIM_LIGHTING");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(rimColorProp, rimColorProp.displayName);
                materialEditor.ShaderProperty(rimMinProp, rimMinProp.displayName);
                materialEditor.ShaderProperty(rimMaxProp, rimMaxProp.displayName);
                materialEditor.ShaderProperty(rimLightBasedProp, rimLightBasedProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawVertexColorProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "VERTEX_COLOR");
            }
        }

        private void DrawEmissionProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "EMISSION");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(emissionMapProp, emissionMapProp.displayName);
                materialEditor.ShaderProperty(emissionColorProp, emissionColorProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawNormalMapProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "NORMAL_MAP");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.TexturePropertySingleLine(new GUIContent(normalMapTexProp.displayName), normalMapTexProp);
                materialEditor.ShaderProperty(normalSmoothingProp, normalSmoothingProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawSpecularProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "SPECULAR");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                if (targetMat.GetFloat("_SpecularStylized") > 0 || targetMat.GetFloat("_SpecularCrisp") > 0)
                    selectedSpecularType = targetMat.GetFloat("_SpecularStylized") > 0 ? 1 : 2;
                else
                    selectedSpecularType = 0;
                selectedSpecularType = EditorGUILayout.Popup("Type", selectedSpecularType, SPECULAR_TYPES);
                materialEditor.ShaderProperty(specColorProp, specColorProp.displayName);
                if (selectedSpecularType == 0)
                {
                    targetMat.SetFloat("_SpecularStylized", 0); targetMat.SetFloat("_SpecularCrisp", 0);
                    targetMat.DisableKeyword("SPECULAR_STYLIZED"); targetMat.DisableKeyword("SPECULAR_CRISP");
                    materialEditor.ShaderProperty(specRoughnessProp, specRoughnessProp.displayName);
                }
                else
                {
                    materialEditor.ShaderProperty(specSizeProp, specSizeProp.displayName);
                    if (selectedSpecularType == 1)
                    {
                        targetMat.SetFloat("_SpecularStylized", 1); targetMat.SetFloat("_SpecularCrisp", 0);
                        targetMat.EnableKeyword("SPECULAR_STYLIZED"); targetMat.DisableKeyword("SPECULAR_CRISP");
                        materialEditor.ShaderProperty(specSmoothnessProp, specSmoothnessProp.displayName);
                    }
                    else
                    {
                        targetMat.SetFloat("_SpecularStylized", 0); targetMat.SetFloat("_SpecularCrisp", 1);
                        targetMat.DisableKeyword("SPECULAR_STYLIZED"); targetMat.EnableKeyword("SPECULAR_CRISP");
                    }
                }
                materialEditor.TexturePropertySingleLine(new GUIContent(specTextureProp.displayName), specTextureProp);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawOverlayTextureProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v1 = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "OVERLAY_TEXTURE");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(overlayTintProp, overlayTintProp.displayName);
                materialEditor.TexturePropertySingleLine(new GUIContent(overlayTexProp.displayName), overlayTexProp);
                using (var v2 = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                {
                    DrawShaderKeywordToggle(overlayProjProp, "OVERLAY_PROJECTION");
                    if (overlayProjProp.floatValue > 0)
                    {
                        EditorGUILayout.LabelField(projAngleProp.displayName);
                        EditorGUILayout.BeginHorizontal();
                        Vector4 anglePropValue = projAngleProp.vectorValue;
                        anglePropValue.x = EditorGUILayout.Slider(anglePropValue.x, -1f, 1f);
                        anglePropValue.y = EditorGUILayout.Slider(anglePropValue.y, -1f, 1f);
                        projAngleProp.vectorValue = anglePropValue;
                        EditorGUILayout.EndHorizontal();
                        materialEditor.ShaderProperty(projScaleOffsetProp, projScaleOffsetProp.displayName);
                    }
                }
                --EditorGUI.indentLevel;
            }
        }

        private void DrawGradientProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "GRADIENT");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(gradientPosProp, gradientPosProp.displayName);
                materialEditor.ShaderProperty(gradientSizeProp, gradientSizeProp.displayName);
                materialEditor.ShaderProperty(gradientTopColorProp, gradientTopColorProp.displayName);
                materialEditor.ShaderProperty(gradientBottomColorProp, gradientBottomColorProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawPlaneClippingProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "PLANE_CLIPPING");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.ShaderProperty(clipSectionColorProp, clipSectionColorProp.displayName);
                materialEditor.ShaderProperty(clipSectionEmmisiveProp, clipSectionEmmisiveProp.displayName);
                materialEditor.ShaderProperty(clipPlanePosProp, clipPlanePosProp.displayName);
                materialEditor.ShaderProperty(clipPlaneNormalProp, clipPlaneNormalProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawDisplacementProperties(MaterialProperty toggleProp, MaterialEditor materialEditor)
        {
            using (var v = new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                DrawShaderKeywordToggle(toggleProp, "DISPLACEMENT");
                if (toggleProp.floatValue <= 0)
                    return;
                ++EditorGUI.indentLevel;
                materialEditor.TexturePropertySingleLine(new GUIContent(displacementMapProp.displayName), displacementMapProp);
                materialEditor.ShaderProperty(displacementHeightProp, displacementHeightProp.displayName);
                --EditorGUI.indentLevel;
            }
        }

        private void DrawShaderKeywordToggle(MaterialProperty toggleProp, string keyword)
        {
            FontStyle originalFontStyle = EditorStyles.label.fontStyle;
            EditorStyles.label.fontStyle = toggleProp.floatValue > 0 ? FontStyle.Bold : FontStyle.Normal;
            toggleProp.floatValue = EditorGUILayout.Toggle(toggleProp.displayName, toggleProp.floatValue > 0) ? 1f : 0f;
            if (toggleProp.floatValue > 0)
                targetMat.EnableKeyword(keyword);
            else
                targetMat.DisableKeyword(keyword);
            EditorStyles.label.fontStyle = originalFontStyle;
        }

        private void DrawShaderKeywordToggle(MaterialProperty toggleProp, string keyword, string tooltip)
        {
            FontStyle originalFontStyle = EditorStyles.label.fontStyle;
            EditorStyles.label.fontStyle = toggleProp.floatValue > 0 ? FontStyle.Bold : FontStyle.Normal;
            toggleProp.floatValue = EditorGUILayout.Toggle(new GUIContent(toggleProp.displayName, tooltip), toggleProp.floatValue > 0) ? 1f : 0f;
            if (toggleProp.floatValue > 0)
                targetMat.EnableKeyword(keyword);
            else
                targetMat.DisableKeyword(keyword);
            EditorStyles.label.fontStyle = originalFontStyle;
        }
    }
}