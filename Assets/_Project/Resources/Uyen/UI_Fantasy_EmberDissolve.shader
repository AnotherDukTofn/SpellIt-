Shader "Custom/UI_Fantasy_EmberDissolve"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Base)]
        _BgColor ("Background Color", Color) = (0.1, 0.1, 0.1, 1)
        
        [Header(Dissolve)]
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0
        _NoiseTex ("Noise Texture (R)", 2D) = "white" {}
        _BurnColor ("Burn Edge Color", Color) = (1, 0.4, 0, 1)
        _BurnWidth ("Burn Width", Range(0, 0.2)) = 0.05
        _BurnGlow ("Burn Glow Intensity", Float) = 2.0

        [Header(Settings)]
        _CornerRadius ("Corner Radius", Float) = 15.0
        
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

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _BgColor;
            float _DissolveAmount;
            float4 _BurnColor;
            float _BurnWidth;
            float _BurnGlow;
            float _CornerRadius;

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

                // Dissolve Logic
                float noise = tex2D(_NoiseTex, uv).r;
                float threshold = _DissolveAmount * 1.1; // Ensure it clears fully
                
                if (noise < threshold - _BurnWidth) discard;
                
                float burnMask = smoothstep(threshold - _BurnWidth, threshold, noise);
                float burnEdge = (1.0 - burnMask) * step(0.001, _DissolveAmount);

                fixed4 finalColor = _BgColor;
                finalColor.rgb = lerp(finalColor.rgb, _BurnColor.rgb * _BurnGlow, burnEdge);
                
                finalColor *= tex2D(_MainTex, uv) * IN.color;
                finalColor.a *= panelMask * burnMask;
                
                return finalColor;
            }
            ENDCG
        }
    }
}
