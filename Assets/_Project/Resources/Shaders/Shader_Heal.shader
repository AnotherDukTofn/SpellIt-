Shader "Unlit/heal"
{
    Properties
    {
        [HDR] _Color ("Màu Hồi Máu", Color) = (0.2, 1.0, 0.2, 1) 
        _MainTex ("Ảnh Năng Lượng (Texture)", 2D) = "white" {}
        
        _ScrollSpeedY ("Tốc độ cuộn dọc", Float) = -1.5
        _ScrollSpeedX ("Tốc độ cuộn ngang", Float) = 0.5

        // KHÓA CỨNG ĐỘ MỜ
        _Opacity ("Chốt cứng độ hiển thị", Range(0.0, 1.0)) = 0.3
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Blend SrcAlpha One 
            ZWrite Off
            Cull Off 

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0; 
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _Color;
            float _ScrollSpeedY;
            float _ScrollSpeedX;
            float _Opacity;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                OUT.uv = IN.uv;
                OUT.uv.y += _Time.y * _ScrollSpeedY; 
                OUT.uv.x += _Time.y * _ScrollSpeedX; 
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, IN.uv);

                // Ép cứng độ mờ bằng thanh kéo _Opacity.
                float finalAlpha = texColor.a * _Opacity;

                return texColor * _Color * finalAlpha;
            }
            ENDHLSL
        }
    }
}