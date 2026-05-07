Shader "Custom/UI_Fantasy_GoldEngrave"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Base Metal)]
        _MetalColor ("Metal Base Color", Color) = (0.2, 0.15, 0.1, 1)
        _GoldColor ("Gold Shine Color", Color) = (1, 0.8, 0.3, 1)
        
        [Header(Engraving)]
        _EngraveTex ("Engrave Pattern (A)", 2D) = "black" {}
        _EngraveDepth ("Engrave Depth", Range(0, 0.1)) = 0.03
        
        [Header(Light Settings)]
        _LightDir ("Light Direction (X, Y)", Vector) = (1, 1, 0, 0)
        _GlintPower ("Glint Sharpness", Range(1, 50)) = 15
        _GlintStrength ("Glint Intensity", Range(0, 5)) = 2

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
            sampler2D _EngraveTex;
            float4 _MetalColor;
            float4 _GoldColor;
            float _EngraveDepth;
            float4 _LightDir;
            float _GlintPower;
            float _GlintStrength;
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

                // Engraving normal approximation
                float h = tex2D(_EngraveTex, uv).a;
                float hx = tex2D(_EngraveTex, uv + float2(0.01, 0)).a;
                float hy = tex2D(_EngraveTex, uv + float2(0, 0.01)).a;
                float2 normal = float2(hx - h, hy - h) * _EngraveDepth * 100.0;
                
                // Lighting
                float2 light = normalize(_LightDir.xy);
                float diffuse = saturate(dot(normal, light) * 0.5 + 0.5);
                float glint = pow(saturate(dot(normal, light)), _GlintPower) * _GlintStrength;

                fixed4 finalColor = lerp(_MetalColor, _GoldColor, h);
                finalColor.rgb *= diffuse;
                finalColor.rgb += glint * _GoldColor.rgb;
                
                finalColor.a *= panelMask;
                return finalColor * IN.color;
            }
            ENDCG
        }
    }
}
