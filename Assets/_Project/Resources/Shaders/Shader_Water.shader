Shader "Custom/StylizedWater"
{
    Properties
    {
        _DepthColor ("Depth Color", Color) = (0.0, 0.4, 0.8, 0.9)
        _ShallowColor ("Shallow Color", Color) = (0.2, 0.7, 1.0, 0.8)
        _DepthDistance ("Depth Distance", Float) = 2.0
        
        _FoamColor ("Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _FoamAmount ("Foam Amount", Range(0.01, 5.0)) = 0.5
        _FoamSharpness ("Foam Sharpness", Range(0.0, 1.0)) = 0.5
        
        _WaveSpeed ("Wave Speed", Float) = 1.0
        _WaveScale ("Wave Scale", Float) = 1.0
        _WaveHeight ("Wave Height", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 screenPos    : TEXCOORD1;
                float3 positionWS   : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _DepthColor;
                half4 _ShallowColor;
                float _DepthDistance;
                
                half4 _FoamColor;
                float _FoamAmount;
                float _FoamSharpness;
                
                float _WaveSpeed;
                float _WaveScale;
                float _WaveHeight;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                
                // Vertex wave animation
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float wave = sin(positionWS.x * _WaveScale + _Time.y * _WaveSpeed) 
                           + cos(positionWS.z * _WaveScale + _Time.y * _WaveSpeed);
                positionWS.y += wave * _WaveHeight;
                
                output.positionWS = positionWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.uv = input.uv;
                
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Screen UV for depth sampling
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                
                // Sample scene depth
                float rawDepth = SampleSceneDepth(screenUV);
                
                // Calculate depth difference (supports both Ortho and Perspective)
                float depthDiff;
                
                if (unity_OrthoParams.w > 0.5)
                {
                    // --- Orthographic camera ---
                    float sceneDepthOrtho;
                    #if UNITY_REVERSED_Z
                        sceneDepthOrtho = lerp(_ProjectionParams.z, _ProjectionParams.y, rawDepth);
                    #else
                        sceneDepthOrtho = lerp(_ProjectionParams.y, _ProjectionParams.z, rawDepth);
                    #endif
                    
                    float surfDepthOrtho = -TransformWorldToView(float4(input.positionWS, 1.0)).z;
                    depthDiff = max(0, sceneDepthOrtho - surfDepthOrtho);
                }
                else
                {
                    // --- Perspective camera ---
                    float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);
                    float surfZ = input.screenPos.w;
                    depthDiff = max(0, sceneZ - surfZ);
                }
                
                // Foam: procedural noise along edges
                float noise = sin(input.positionWS.x * 5.0 + _Time.y * 3.0) 
                            * cos(input.positionWS.z * 5.0 + _Time.y * 2.0);
                float foamRaw = 1.0 - saturate(depthDiff / _FoamAmount);
                foamRaw = saturate(foamRaw + noise * 0.15);
                float foam = step(_FoamSharpness, foamRaw);
                
                // Water color gradient (shallow -> deep)
                float depthGradient = saturate(depthDiff / _DepthDistance);
                half4 waterColor = lerp(_ShallowColor, _DepthColor, depthGradient);
                
                // Composite: overlay foam on water
                half4 finalColor = lerp(waterColor, _FoamColor, foam);
                finalColor.a = lerp(waterColor.a, 1.0, foam);
                
                // --- LIGHTING ---
                
                // Analytical normal from wave function for smooth shading
                float dx = cos(input.positionWS.x * _WaveScale + _Time.y * _WaveSpeed) * _WaveScale * _WaveHeight;
                float dz = -sin(input.positionWS.z * _WaveScale + _Time.y * _WaveSpeed) * _WaveScale * _WaveHeight;
                float3 normalWS = normalize(float3(-dx, 1.0, -dz));
                
                // Main directional light
                Light mainLight = GetMainLight();
                half NdotL = saturate(dot(normalWS, mainLight.direction));
                
                // Ambient lighting (spherical harmonics)
                half3 ambient = SampleSH(normalWS);
                
                // Diffuse lighting
                half3 lighting = ambient + mainLight.color * NdotL;
                
                // Stylized Specular highlight (only on water, not foam)
                float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3 halfVector = normalize(mainLight.direction + viewDir);
                half NdotH = saturate(dot(normalWS, halfVector));
                half specular = pow(NdotH, 128.0) * step(0.5, NdotL); // Sharp stylized specular
                
                // Apply lighting
                finalColor.rgb = finalColor.rgb * lighting + (specular * mainLight.color * 0.8 * (1.0 - foam));

                // Apply Fog
                finalColor.rgb = MixFog(finalColor.rgb, ComputeFogFactor(input.positionCS.z));
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}
