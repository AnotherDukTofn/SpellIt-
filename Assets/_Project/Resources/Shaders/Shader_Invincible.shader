Shader "Unlit/invincible"
{
    Properties
    {
        [HDR] _Mau ("Màu I-frame", Color) = (1, 0.3, 0.3, 1)

        _DoSacVien ("Độ sắc viền (Fresnel Power)", Float) = 3.0
        _DoDayVien ("Độ dày viền (Fresnel Bias)", Float) = 0.1

        _TocDoNhay ("Tốc độ nhấp nháy", Float) = 10.0
        _DoMoToiThieu ("Độ mờ tối thiểu", Range(0.0, 1.0)) = 0.1

        _TocDoSong ("Tốc độ sóng", Float) = 4.0
        _DoManhSong ("Độ mạnh sóng", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100

        Pass
        {
            Blend SrcAlpha One
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DauVao
            {
                float4 viTriOS : POSITION;
                float3 phapTuyenOS : NORMAL;
            };

            struct DauRa
            {
                float4 viTriHCS : SV_POSITION;
                float3 phapTuyenWS : TEXCOORD0;
                float3 huongNhinWS : TEXCOORD1;
                float3 viTriWS : TEXCOORD2;
            };

            float4 _Mau;
            float _DoSacVien;
            float _DoDayVien;
            float _TocDoNhay;
            float _DoMoToiThieu;
            float _TocDoSong;
            float _DoManhSong;

            DauRa vert(DauVao IN)
            {
                DauRa OUT;

                OUT.viTriHCS = TransformObjectToHClip(IN.viTriOS.xyz);
                OUT.phapTuyenWS = TransformObjectToWorldNormal(IN.phapTuyenOS);

                float3 viTriWS = TransformObjectToWorld(IN.viTriOS.xyz);
                OUT.viTriWS = viTriWS;

                OUT.huongNhinWS = normalize(_WorldSpaceCameraPos.xyz - viTriWS);

                return OUT;
            }

            half4 frag(DauRa IN) : SV_Target
            {
                float3 phapTuyen = normalize(IN.phapTuyenWS);

                // ===== VIỀN FRESNEL =====
                float fresnel = dot(phapTuyen, IN.huongNhinWS);
                fresnel = 1.0 - saturate(fresnel);
                fresnel = pow(fresnel + _DoDayVien, _DoSacVien);

                // ===== NHẤP NHÁY MƯỢT =====
                float nhip = sin(_Time.y * _TocDoNhay) * 0.5 + 0.5;
                nhip = smoothstep(0.2, 0.8, nhip);

                float alphaNhay = lerp(_DoMoToiThieu, 1.0, nhip);

                // ===== SÓNG CHẠY TRÊN NHÂN VẬT =====
                float song = sin(IN.viTriWS.y * 5.0 + _Time.y * _TocDoSong);
                song = song * 0.5 + 0.5;

                float hieuUngSong = lerp(1.0, song, _DoManhSong);

                // ===== KẾT HỢP =====
                float doTrong = fresnel * alphaNhay * hieuUngSong;

                return _Mau * doTrong;
            }
            ENDHLSL
        }
    }
}