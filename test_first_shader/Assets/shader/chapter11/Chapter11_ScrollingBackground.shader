Shader "Unlit/Chapter11_ScrollingBackground"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DetailTex ("Detail Texture",2D  ) = "white" {}
        _ScrollX ("Scroll X",Float) = 1
        _ScrollX2("Scroll X 2",Float) = 1
        _Multiplier("Multiplier",Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
  

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite  Off
            Blend  SrcAlpha OneMinusSrcAlpha  
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
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _ScrollX2;
            float _Multiplier;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex)+frac(float2(_ScrollX,0.0f)*_Time.y);//frac 取小数部分
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_DetailTex)+frac(float2(_ScrollX2,0.0f)*_Time.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed4 color1 = tex2D(_MainTex,i.uv.xy);
               fixed4 color2 = tex2D(_DetailTex,i.uv.zw);

               fixed4 color = lerp(color1,color2,color2.a);

               color.rgb *= _Multiplier;
               
               return color;
            }
            ENDCG
        }
    }
}
