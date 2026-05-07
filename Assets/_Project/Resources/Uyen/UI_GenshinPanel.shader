Shader "Custom/UI_GenshinPanel_Clean"
{
    Properties
    {
        _ColorA ("Top Color", Color) = (0.3,0.5,1,1)
        _ColorB ("Bottom Color", Color) = (0.6,0.2,1,1)

        _MainTex ("Base Tex (Sóng nền)", 2D) = "white" {}

        _ShineColor ("Sparkle Color", Color) = (1,1,1,1)
        _ShineSpeed ("Sparkle Animation Speed", Float) = 0.5
        
        _SparkleTex ("Sparkle Noise Tex", 2D) = "white" {}
        _SparklePower ("Sparkle Power", Float) = 0.3

        _RimColor ("Rim Color", Color) = (0.6,0.8,1,1)
        _RimPower ("Rim Power", Float) = 2

        _Hover ("Hover", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _SparkleTex;

            float4 _ColorA, _ColorB;
            float4 _ShineColor;
            float _ShineSpeed;
            float _SparklePower;
            float4 _RimColor;
            float _RimPower;
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

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                // 1. Gradient nền
                float4 col = lerp(_ColorB, _ColorA, smoothstep(0, 1, uv.y));

                // 2. Lấy mask sóng từ Base Tex (giữ lại cái sóng đằng sau)
                float baseMask = tex2D(_MainTex, uv).r;
                baseMask = smoothstep(0.2, 0.8, baseMask);

                // 3. Hiệu ứng Sparkle (ánh sao lấp lánh chạy trên sóng)
                float2 sparkleUV = uv;
                // Làm cho các đốm sáng di chuyển chậm hơn để trông tự nhiên
                sparkleUV.x += _Time.y * _ShineSpeed; 
                
                float sparkle = tex2D(_SparkleTex, sparkleUV * 3).r;

                // Chỉ cho lấp lánh xuất hiện ở những nơi có vân sóng (baseMask)
                float finalSparkle = sparkle * baseMask * _SparklePower;
                
                // Cộng hiệu ứng sáng vào màu tổng thể
                col.rgb += _ShineColor.rgb * finalSparkle;

                // 4. Rim light (viền sáng dịu ở giữa tỏa ra)
                float2 center = uv - 0.5;
                float rim = 1 - saturate(length(center) * _RimPower);
                col.rgb += rim * _RimColor.rgb * 0.4;

                // 5. Hiệu ứng Hover
                col.rgb *= lerp(1, 1.2, _Hover);

                return col;
            }
            ENDCG
        }
    }
}