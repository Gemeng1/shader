Shader "Unlit/Chapter11_ImageSequenceAnimation"
{
    Properties
    {
        _Color ("color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _HAmount ("Horizeontal Amount",Float) = 4
        _VAmount ("Vertical Amount",Float) = 4
        _Speed ("Speed",Range(1,100)) = 30
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}

            ZWrite  off //关闭深度缓冲

            Blend  SrcAlpha OneMinusSrcAlpha //开启混合模式


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HAmount;
            float _VAmount;
            float _Speed;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time =  floor(_Time.y*_Speed); 
                float row = floor(time/_HAmount);
                float column = time - row*_VAmount;
                half2 uv = i.uv + half2(column,-row);
                uv.x /= _HAmount;
                uv.y /= _VAmount;

                fixed4 c = tex2D(_MainTex,uv);
                c.rgb *= _Color;

                return c;

            }
            ENDCG
        }
    }
}
