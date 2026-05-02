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

        // --- BÍ KÍP BÓP NHỌN ĐỈNH ---
        _TaperScale ("Độ thu nhỏ ở đỉnh (0 là nhọn hoắt)", Float) = 0.0
        _TaperBottom ("Tọa độ Y ở đáy lò xo", Float) = -1.0
        _TaperTop ("Tọa độ Y ở đỉnh lò xo", Float) = 1.0
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

            // Khai báo biến bóp đỉnh
            float _TaperScale;
            float _TaperBottom;
            float _TaperTop;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // --- PHÉP THUẬT BÓP NGHẸT ĐỈNH ---
                // Tính toán xem điểm này đang nằm ở khúc nào của lò xo (từ 0 đến 1)
                float heightRatio = saturate((IN.positionOS.y - _TaperBottom) / (_TaperTop - _TaperBottom));
                
                // Nội suy kích thước: Dưới đáy bằng 1.0 (to bình thường), lên đỉnh thu về _TaperScale
                float widthScale = lerp(1.0, _TaperScale, heightRatio);
                
                // Nhân trục X và Z để bóp khối 3D lại, giữ nguyên chiều cao Y
                IN.positionOS.xz *= widthScale;
                // -------------------------------------

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