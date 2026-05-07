Shader "Custom/UI_FantasyButton"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Base Appearance)]
        _SurfaceColor ("Surface Color", Color) = (0.1, 0.1, 0.1, 0.6)
        _AccentColor ("Accent/Glow Color", Color) = (0.6, 0.3, 0.1, 1)
        _BorderColor ("Border Color", Color) = (0.4, 0.3, 0.2, 1)

        [Header(Hover Settings)]
        _Hover ("Hover Progress", Range(0, 1)) = 0
        _GlowIntensity ("Grace Glow Intensity", Range(0, 5)) = 0.5
        _GlowIntensityInactive ("Glow Inactive", Range(0, 1)) = 0.1
        _GlowScale ("Grace Glow Scale", Range(0, 2)) = 1.2
        _GlowScaleInactive ("Glow Scale Inactive", Range(0, 2)) = 0.5
        _BorderIntensity ("Border Glow Power", Range(0, 10)) = 3.0
        _BorderIntensityInactive ("Border Inactive Power", Range(0, 2)) = 0.5
        _BorderWidth ("Border Width", Range(0.01, 0.2)) = 0.05
        
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
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

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
            fixed4 _Color, _SurfaceColor, _AccentColor, _BorderColor;
            float _Hover, _GlowIntensity, _GlowIntensityInactive, _GlowScale, _GlowScaleInactive, _BorderIntensity, _BorderIntensityInactive, _BorderWidth;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float2 centerUV = uv - 0.5;
                
                // 1. Background (Horizontal Gradient)
                float bgMask = saturate(1.0 - abs(centerUV.x) * 2.0);
                fixed4 bg = _SurfaceColor;
                bg.a *= pow(bgMask, 2.0) * lerp(0.5, 1.0, _Hover);

                // 2. Glowing Borders (Top & Bottom)
                float borderMask = smoothstep(0.5 - _BorderWidth, 0.5, abs(centerUV.y));
                float pulse = 1.0 + sin(_Time.y * 3.0) * 0.15;
                
                // Lerp cường độ viền dựa trên Hover
                float currentBorderInt = lerp(_BorderIntensityInactive, _BorderIntensity, _Hover);
                fixed4 border = _BorderColor * borderMask * currentBorderInt * pulse;

                // 3. Grace Hover (Radial Glow)
                float dist = length(centerUV);
                
                // Tính toán riêng biệt cho 2 trạng thái để đảm bảo độ mượt
                float maskInactive = saturate(1.0 - dist * (2.0 / max(0.01, _GlowScaleInactive)));
                maskInactive = pow(maskInactive, 3.0) * _GlowIntensityInactive;
                
                float maskActive = saturate(1.0 - dist * (2.0 / max(0.01, _GlowScale)));
                maskActive = pow(maskActive, 3.0) * _GlowIntensity;
                
                float graceGlow = lerp(maskInactive, maskActive, _Hover);
                fixed4 glow = _AccentColor * graceGlow;

                // 4. Final Composition
                fixed4 final = bg;
                final.rgb += glow.rgb + border.rgb;
                final.a = saturate(final.a + glow.a + border.a);

                return final * tex2D(_MainTex, uv) * IN.color;
            }
            ENDCG
        }
    }
}
