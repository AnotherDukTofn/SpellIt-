Shader "Custom/UI_Fantasy_Master"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Base Material)]
        _BgColor1 ("Dark Base Color", Color) = (0.05, 0.04, 0.03, 1)
        _BgColor2 ("Light Base Color", Color) = (0.15, 0.12, 0.1, 1)
        _MainNoise ("Surface Noise", 2D) = "white" {}
        _NoiseStrength ("Noise Intensity", Range(0, 1)) = 0.2
        _Vignette ("Vignette Depth", Range(0, 2)) = 0.8

        [Header(Engraving Ornament)]
        _OrnamentTex ("Ornament (Alpha Mask)", 2D) = "black" {}
        _OrnamentColor ("Ornament Color", Color) = (0.4, 0.3, 0.1, 1)
        _EngraveDepth ("Engrave Depth", Range(0, 0.1)) = 0.02

        [Header(Golden Border)]
        _GoldColor1 ("Bright Gold", Color) = (1.0, 0.85, 0.4, 1)
        _GoldColor2 ("Antique Gold", Color) = (0.5, 0.35, 0.1, 1)
        _BorderWidth ("Border Width (Pixels)", Float) = 2.0
        _GlintStrength ("Specular Glint", Range(0, 5)) = 1.5
        _BorderSpeed ("Flow Speed", Float) = 0.5

        [Header(Ember & Magic)]
        _EmberColor ("Ember Color", Color) = (1.0, 0.4, 0.1, 1)
        _EmberStrength ("Ember Glow", Range(0, 2)) = 0.5
        _PulseSpeed ("Breath Speed", Float) = 1.2
        
        [Header(Dissolve Effect)]
        _Dissolve ("Dissolve Amount", Range(0, 1)) = 0
        _BurnWidth ("Burn Edge Width", Range(0, 0.2)) = 0.05

        [Header(Settings)]
        _CornerRadius ("Corner Radius", Float) = 12.0
        
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
            sampler2D _MainNoise;
            sampler2D _OrnamentTex;
            fixed4 _Color;
            
            float4 _BgColor1;
            float4 _BgColor2;
            float _NoiseStrength;
            float _Vignette;
            
            float4 _OrnamentColor;
            float _EngraveDepth;
            
            float4 _GoldColor1;
            float4 _GoldColor2;
            float _BorderWidth;
            float _GlintStrength;
            float _BorderSpeed;
            
            float4 _EmberColor;
            float _EmberStrength;
            float _PulseSpeed;
            
            float _Dissolve;
            float _BurnWidth;
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
                // Pixel Size & Coordinates
                float2 uv = IN.texcoord;
                float2 pixelSize = 1.0 / float2(length(ddx(uv)), length(ddy(uv)));
                float2 centeredP = (uv - 0.5) * pixelSize;
                
                // Shape SDF
                float dist = roundedBoxSDF(centeredP, pixelSize * 0.5, _CornerRadius);
                float aa = fwidth(dist);
                float panelMask = smoothstep(aa, -aa, dist);

                // --- 1. DISSOLVE LOGIC ---
                float noiseVal = hash(uv * 5.0);
                float dMask = _Dissolve * 1.2; // Slightly overshoot for full clear
                if (noiseVal < dMask - _BurnWidth) discard;
                float burnEdge = smoothstep(dMask - _BurnWidth, dMask, noiseVal);

                // --- 2. BASE MATERIAL (Parchment/Stone) ---
                float bgGrad = uv.y; // Standard top-bottom
                fixed4 baseColor = lerp(_BgColor1, _BgColor2, bgGrad);
                
                // Surface Noise
                float4 surfaceNoise = tex2D(_MainNoise, uv * 2.0);
                baseColor.rgb *= lerp(1.0, surfaceNoise.r, _NoiseStrength);
                
                // Vignette
                float vignette = length(uv - 0.5) * 2.0;
                baseColor.rgb *= lerp(1.0, 1.0 - _Vignette * 0.5, saturate(vignette));

                // --- 3. ORNAMENT ENGRAVING ---
                // Simple 3D effect by offsetting samples
                float ornament = tex2D(_OrnamentTex, uv).a;
                float ornamentOffset = tex2D(_OrnamentTex, uv + float2(_EngraveDepth, _EngraveDepth) * 0.1).a;
                float engraveShadow = saturate(ornamentOffset - ornament);
                
                fixed4 finalBase = baseColor;
                finalBase.rgb = lerp(finalBase.rgb, _OrnamentColor.rgb, ornament * _OrnamentColor.a);
                finalBase.rgb -= engraveShadow * 0.5; // Depth shadow

                // --- 4. GOLDEN BORDER ---
                float borderInner = dist + _BorderWidth;
                float borderMask = smoothstep(aa, -aa, dist) * smoothstep(-aa, aa, borderInner);
                
                // Flowing Border Gradient
                float aspect = pixelSize.x / pixelSize.y;
                float angle = atan2(centeredP.y * aspect, centeredP.x);
                float flow = frac((angle / (2.0 * 3.14159)) + 0.5 + _Time.y * _BorderSpeed);
                fixed4 borderColor = lerp(_GoldColor1, _GoldColor2, abs(flow * 2.0 - 1.0));
                
                // Specular Glint (Simulated)
                float glint = pow(abs(sin(angle + _Time.y * 2.0)), 10.0) * _GlintStrength;
                borderColor.rgb += glint * _GoldColor1.rgb;

                // --- 5. EMBERS & PULSE ---
                float pulse = 1.0 + sin(_Time.y * _PulseSpeed) * 0.2;
                borderColor.rgb *= pulse;
                
                // Ember noise
                float emberNoise = hash(uv * 20.0 + _Time.y * 0.5);
                float emberMask = smoothstep(0.95, 1.0, emberNoise) * _EmberStrength;
                finalBase.rgb += _EmberColor.rgb * emberMask;

                // --- 6. FINAL COMBINE ---
                fixed4 finalColor = lerp(finalBase, borderColor, borderMask);
                
                // Apply Burn Edge color
                finalColor.rgb = lerp(finalColor.rgb, _EmberColor.rgb * 5.0, (1.0 - burnEdge) * (dMask > 0));
                
                // Apply Sprite Texture & Vertex Color
                finalColor *= tex2D(_MainTex, uv) * IN.color;
                
                // Final Alpha Mask
                finalColor.a *= panelMask * burnEdge;
                
                return finalColor;
            }
            ENDCG
        }
    }
}
