Shader "Custom/UI_Fantasy_FracturedCrystal"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Crystal)]
        _CrystalColor ("Crystal Base Color", Color) = (0.4, 0.6, 1, 0.6)
        _CrackColor ("Crack Glow Color", Color) = (0.2, 0.8, 1, 1)
        _CrackTex ("Crack Pattern (A)", 2D) = "black" {}
        _CrackIntensity ("Glow Intensity", Range(0, 5)) = 1.5
        
        [Header(Refraction)]
        _Distortion ("Distortion Strength", Range(0, 0.1)) = 0.02
        
        [Header(Settings)]
        _CornerRadius ("Corner Radius", Float) = 25.0
        
        [Header(UI Support)]
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }

        Stencil { Ref [_Stencil] Comp [_StencilComp] Pass [_StencilOp] ReadMask [_StencilReadMask] WriteMask [_StencilWriteMask] }

        Cull Off Lighting Off ZWrite Off ZTest [unity_GUIZTestMode] Blend SrcAlpha OneMinusSrcAlpha ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t { float4 vertex : POSITION; float4 color : COLOR; float2 texcoord : TEXCOORD0; };
            struct v2f { float4 vertex : SV_POSITION; fixed4 color : COLOR; float2 texcoord : TEXCOORD0; };

            sampler2D _MainTex, _CrackTex;
            float4 _CrystalColor, _CrackColor;
            float _CrackIntensity, _Distortion, _CornerRadius;

            v2f vert(appdata_t v) {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color;
                return OUT;
            }

            float roundedBoxSDF(float2 p, float2 size, float r) {
                float2 d = abs(p) - size + r;
                return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
            }

            fixed4 frag(v2f IN) : SV_Target {
                float2 uv = IN.texcoord;
                float2 pixelSize = 1.0 / float2(length(ddx(uv)), length(ddy(uv)));
                float2 p = (uv - 0.5) * pixelSize;
                
                float dist = roundedBoxSDF(p, pixelSize * 0.5, _CornerRadius);
                float panelMask = smoothstep(fwidth(dist), -fwidth(dist), dist);

                // Distortion for refraction effect
                float crackPattern = tex2D(_CrackTex, uv).a;
                float2 distortUV = uv + (crackPattern - 0.5) * _Distortion;
                
                fixed4 crystal = _CrystalColor;
                fixed4 mainTex = tex2D(_MainTex, distortUV);
                
                // Glowing Cracks
                float pulse = 0.8 + sin(_Time.y * 2.0) * 0.2;
                fixed4 cracks = _CrackColor * crackPattern * _CrackIntensity * pulse;

                fixed4 finalColor = crystal * mainTex;
                finalColor.rgb += cracks.rgb;
                finalColor.a = max(finalColor.a, cracks.a) * panelMask;
                
                return finalColor * IN.color;
            }
            ENDCG
        }
    }
}
