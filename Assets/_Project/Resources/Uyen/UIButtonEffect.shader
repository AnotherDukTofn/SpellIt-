Shader "Custom/UIButtonEffect_AdditiveHover"
{
    Properties
    {
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}
        
        [Header(Gradient Colors)]
        _ColorTop ("Gradient Top", Color) = (1,1,1,1)
        _ColorBot ("Gradient Bottom", Color) = (0.8,0.8,0.8,1)
        
        [Header(Interaction Colors)]
        // BÂY GIỜ LÀ MÀU ĐỂ CỘNG THÊM (Chọn màu trắng để sáng lên)
        _HoverColor ("Hover Additive Color", Color) = (0.3, 0.3, 0.3, 1) 
        // Vẫn dùng làm bộ nhân để làm tối nút
        _PressedColor ("Pressed Multiplier", Color) = (0.7, 0.7, 0.7, 1)
        
        [Header(Shine Settings)]
        _ShineColor ("Shine Color", Color) = (1,1,1,1)
        _ShineWidth ("Shine Width", Range(0,1)) = 0.15
        _ShineSpeed ("Shine Speed", Float) = 1.5
        
        [HideInInspector] _IsHovering ("Is Hovering", Float) = 0
        [HideInInspector] _IsPressed ("Is Pressed", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            fixed4 _ColorTop, _ColorBot, _HoverColor, _PressedColor, _ShineColor;
            float _IsHovering, _IsPressed, _ShineWidth, _ShineSpeed;
            sampler2D _MainTex;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // 1. Tạo Gradient gốc
                fixed4 col = lerp(_ColorBot, _ColorTop, i.uv.y);
                
                // 2. Tính toán màu dựa trên tương tác (Logic mới: Cộng màu)
                fixed3 hoverAddColor = fixed3(0, 0, 0);
                if (_IsHovering > 0.5) {
                    hoverAddColor = _HoverColor.rgb; 
                }
                
                // Cộng sáng vào nền
                col.rgb += hoverAddColor;

                // Xử lý khi nhấn (Tắt cộng sáng và làm tối)
                if (_IsPressed > 0.5) {
                    // Trả về màu gradient gốc rồi mới làm tối
                    fixed3 originalCol = col.rgb - hoverAddColor;
                    col.rgb = originalCol * _PressedColor.rgb;
                }

                // 3. Hiệu ứng tia sáng chạy chéo (Giữ nguyên)
                float shinePos = frac(_Time.y * _ShineSpeed * 0.1);
                float shineEdge = frac(i.uv.x + i.uv.y + shinePos);
                float shineMask = smoothstep(1.0 - _ShineWidth, 1.0, shineEdge);
                col.rgb += _ShineColor.rgb * shineMask;

                // 4. Kết hợp với Texture (nếu có) và Alpha
                fixed4 tex = tex2D(_MainTex, i.uv) * i.color;
                col.a *= tex.a;
                
                return col;
            }
            ENDCG
        }
    }
}