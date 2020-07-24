Shader "Unlit/Chapter12_Bloom"
{
   Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bloom("Bloom",2D) = "black"{}
        _LuminanceThreshold("Luminance Threshold",Float) = 0.5
        _BlurSize("Blur Size",Float) = 1.0
    }
    SubShader
    {

        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        struct v2f
        {
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD0 ; 
            
        };

        v2f vertExtractBright(appdata_img  v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;

            return o;
        }

        // template<class T>
        // T Clamp(T x, T min, T max)
        // {
        //     if (x > max)
        //         return max;
        //     if (x < min)
        //         return min;
        //     return x;
        // }
        fixed4 fragExtractBright(v2f i):SV_Target{//获取高亮
            fixed4 c = tex2D(_MainTex,i.uv);
            fixed val = clamp(Luminance(c)-_LuminanceThreshold,0.0,1.0);//限定函数
            return c * val;
        }

        struct v2fBloom
        {
            float4 pos:SV_POSITION;
            half4 uv:TEXCOORD0 ; 
            
        };

        v2fBloom vertBloom(appdata_img  v){
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv.xy = v.texcoord;

            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0-o.uv.w;
            #endif
            return o;
        }

        fixed4 fragBloom(v2fBloom i):SV_Target{
            return tex2D(_MainTex,i.uv.xy)+tex2D(_Bloom,i.uv.zw);
        }
        ENDCG
        // No culling or depth
        ZTest Always Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright 
            ENDCG
        }

        UsePass "Unlit/Chapter12_GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Unlit/Chapter12_GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

        Pass {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    FallBack Off
}
