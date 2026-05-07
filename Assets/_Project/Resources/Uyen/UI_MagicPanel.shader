Shader "Custom/UI_MagicPanel"
{
    Properties
    {
        _ColorA ("Color A", Color) = (0.2,0,0.5,1)
        _ColorB ("Color B", Color) = (0,0.5,1,1)

        _MainTex ("Texture", 2D) = "white" {}

        _ShineColor ("Shine Color", Color) = (1,1,1,1)
        _ShineSpeed ("Shine Speed", Float) = 2
        _ShineWidth ("Shine Width", Float) = 0.2

        _SparkleTex ("Sparkle Texture", 2D) = "white" {}
        _SparkleIntensity ("Sparkle Intensity", Float) = 0.5

        _Hover ("Hover", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _SparkleTex;

            float4 _ColorA;
            float4 _ColorB;

            float4 _ShineColor;
            float _ShineSpeed;
            float _ShineWidth;

            float _SparkleIntensity;
            float _Hover;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float rand(float2 co)
            {
                return frac(sin(dot(co,float2(12.9898,78.233))) * 43758.5453);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                // 🌈 Gradient
                float4 col = lerp(_ColorA, _ColorB, uv.y);

                // ✨ Shine (tia chạy)
                float shine = smoothstep(0.5 - _ShineWidth, 0.5, 
                    abs(uv.x - frac(_Time.y * _ShineSpeed)));

                col.rgb += shine * _ShineColor.rgb;

                // 🌟 Sparkle (bling bling)
                float sparkle = rand(floor(uv * 50 + _Time.y * 5));
                sparkle = step(0.95, sparkle);
                col.rgb += sparkle * _SparkleIntensity;

                // 💡 Fake lighting (giả lập ánh sáng)
                float light = dot(normalize(float2(0.5,1)), normalize(uv - 0.5));
                col.rgb += light * 0.3;

                // 🖱 Hover effect
                col.rgb = lerp(col.rgb, col.rgb * 1.5, _Hover);

                return col;
            }
            ENDCG
        }
    }
}