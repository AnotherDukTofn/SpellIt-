Shader "SpellIt/GhostAfterimage"
{
    Properties
    {
        _Color ("Ghost Color", Color) = (0.3, 0.7, 1.0, 0.8)
        _FresnelPower ("Fresnel Power", Range(0.5, 5.0)) = 2.0
        _FresnelIntensity ("Fresnel Intensity", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent+100"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos     : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
            };

            fixed4 _Color;
            float  _FresnelPower;
            float  _FresnelIntensity;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(i.viewDir);

                // Fresnel: sáng mạnh ở viền, nhạt ở giữa
                float fresnel = 1.0 - saturate(dot(normal, viewDir));
                fresnel = pow(fresnel, _FresnelPower) * _FresnelIntensity;

                fixed4 col = _Color;
                col.rgb += fresnel * col.rgb; // Viền phát sáng cùng tone màu
                col.a *= saturate(_Color.a + fresnel * 0.3);

                return col;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}
