Shader "Custom/UI_Fantasy_Soulstream"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Liquid)]
        _LiquidColor ("Liquid Color", Color) = (0.2, 0.5, 1, 1)
        _FillLevel ("Fill Level", Range(0, 1)) = 0.5
        _WaveSpeed ("Wave Speed", Float) = 2.0
        _WaveHeight ("Wave Height", Range(0, 0.1)) = 0.02
        
        [Header(Bubbles)]
        _BubbleColor ("Bubble Color", Color) = (1, 1, 1, 0.5)
        _BubbleSpeed ("Bubble Speed", Float) = 1.0

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
            float4 _LiquidColor, _BubbleColor;
            float _FillLevel, _WaveSpeed, _WaveHeight, _BubbleSpeed, _CornerRadius;

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

            float hash(float2 p) { return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }

            fixed4 frag(v2f IN) : SV_Target {
                float2 uv = IN.texcoord;
                float2 pixelSize = 1.0 / float2(length(ddx(uv)), length(ddy(uv)));
                float2 p = (uv - 0.5) * pixelSize;
                
                float dist = roundedBoxSDF(p, pixelSize * 0.5, _CornerRadius);
                float panelMask = smoothstep(fwidth(dist), -fwidth(dist), dist);

                // Waves
                float wave = sin(uv.x * 10.0 + _Time.y * _WaveSpeed) * _WaveHeight;
                float liquidMask = step(uv.y, _FillLevel + wave);

                // Bubbles
                float2 bubbleUV = uv * float2(5.0, 2.0);
                bubbleUV.y -= _Time.y * _BubbleSpeed;
                float h = hash(floor(bubbleUV));
                float bubble = smoothstep(0.95, 1.0, h) * liquidMask * 0.3;

                fixed4 finalColor = lerp(fixed4(0,0,0,0.5), _LiquidColor, liquidMask);
                finalColor.rgb += _BubbleColor.rgb * bubble;
                
                finalColor *= tex2D(_MainTex, uv) * IN.color;
                finalColor.a *= panelMask;
                
                return finalColor;
            }
            ENDCG
        }
    }
}
