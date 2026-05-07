Shader "Custom/UI_MinimalMagic"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Background)]
        _BgColor1 ("Background Color 1", Color) = (0.05, 0.05, 0.08, 1)
        _BgColor2 ("Background Color 2", Color) = (0.1, 0.1, 0.15, 1)
        _BgDir ("Background Direction (X, Y)", Vector) = (0, 1, 0, 0)
        _NoiseStrength ("Grain/Noise Strength", Range(0, 0.2)) = 0.05
        _Vignette ("Vignette Strength", Range(0, 2)) = 0.5
        
        [Header(Border)]
        _BorderColor1 ("Border Color 1", Color) = (1, 0.8, 0.4, 1)
        _BorderColor2 ("Border Color 2", Color) = (0.5, 0.3, 0.1, 1)
        _BorderWidth ("Border Width (Pixels)", Float) = 1.5
        _BorderSpeed ("Border Animation Speed", Float) = 0.3
        _PulseSpeed ("Glow Pulse Speed", Float) = 1.0
        _PulseStrength ("Glow Pulse Strength", Range(0, 1)) = 0.3
        
        [Header(Settings)]
        _CornerRadius ("Corner Radius (Pixels)", Float) = 10.0
        
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
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 localPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            fixed4 _Color;
            
            float4 _BgColor1;
            float4 _BgColor2;
            float4 _BgDir;
            float _NoiseStrength;
            float _Vignette;
            
            float4 _BorderColor1;
            float4 _BorderColor2;
            float _BorderWidth;
            float _BorderSpeed;
            float _PulseSpeed;
            float _PulseStrength;
            
            float _CornerRadius;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.localPos = v.vertex;
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            float roundedBoxSDF(float2 p, float2 size, float r)
            {
                float2 d = abs(p) - size + r;
                return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
            }

            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                // Pixel Size Determination
                float2 pixelSize = 1.0 / float2(length(ddx(IN.texcoord)), length(ddy(IN.texcoord)));
                float2 centeredP = (IN.texcoord - 0.5) * pixelSize;
                
                // Shape SDF
                float dist = roundedBoxSDF(centeredP, pixelSize * 0.5, _CornerRadius);
                float aa = fwidth(dist);
                float panelMask = smoothstep(aa, -aa, dist);

                // 1. Background with Noise & Vignette
                float2 bgDir = normalize(_BgDir.xy + 0.00001);
                float bgGrad = dot(IN.texcoord - 0.5, bgDir) + 0.5;
                fixed4 gradColor = lerp(_BgColor1, _BgColor2, saturate(bgGrad));
                
                // Texture Sample
                fixed4 tex = tex2D(_MainTex, IN.texcoord);
                gradColor *= tex;

                // Add Noise (Grain)
                float n = hash(IN.texcoord * 10.0 + _Time.x);
                gradColor.rgb += (n - 0.5) * _NoiseStrength;

                // Vignette (Darken edges)
                float vignette = length(IN.texcoord - 0.5) * 2.0;
                gradColor.rgb *= lerp(1.0, 1.0 - _Vignette * 0.5, saturate(vignette));

                // 2. Border Logic
                float borderInner = dist + _BorderWidth;
                float borderMask = smoothstep(aa, -aa, dist) * smoothstep(-aa, aa, borderInner);

                // 3. Dynamic Fantasy Border
                float aspect = pixelSize.x / pixelSize.y;
                float angle = atan2(centeredP.y * aspect, centeredP.x);
                float borderFlow = frac((angle / (2.0 * 3.14159)) + 0.5 + _Time.y * _BorderSpeed);
                
                fixed4 borderColor = lerp(_BorderColor1, _BorderColor2, abs(borderFlow * 2.0 - 1.0));

                // Pulse Effect (The "Breath" of Grace)
                float pulse = 1.0 + sin(_Time.y * _PulseSpeed) * _PulseStrength;
                borderColor.rgb *= pulse;

                // Final Combine
                fixed4 finalColor = lerp(gradColor, borderColor, borderMask);
                finalColor.a *= panelMask;
                
                return finalColor * IN.color;
            }
            ENDCG
        }
    }
}
