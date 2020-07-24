Shader "Unlit/Chapter15_FogWidthNoise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogDensity("Fog Density",Float) = 1.0
        _FogColor("Fog Color",Color ) = (1,1,1,1)
        _FogStart("Fog Start",Float) = 0.0
        _FogEnd("Fog End",Float) = 2.0
        _NoiseTexture("Noise Texture",2D) = "white"{}
        _FogXSpeed("Fog X Speed",Float) = 1.0
        _FogYSpeed("Fog Y Speed",Float) = 1.0
        _NoiseAmount("Noise Amount",Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D  _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D  _CameraDepthTexture;
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;
        sampler2D _NoiseTexture;
        half _FogXSpeed;
        half _FogYSpeed;
        half _NoiseAmount;
        float4x4 _RayMatrix;

        struct v2f
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
            float2 uv_depth:TEXCOORD1;
            float4 ray:TEXCOORD2;
            
        };

        v2f vert(appdata_img v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;


            int index = 0;
            if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5){
                index = 0;
            }else if(v.texcoord.x > 0.5 && v.texcoord.y < 0.5){
                index = 1;
            }else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5){
                index = 2;
            }else{
                index = 3;
            }

            #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0){

                    o.uv_depth.y = 1 - o.uv_depth.y;
                    index = 3 - index;
                }
            #endif

            o.ray = _RayMatrix[index];

            return  o;
        }

        fixed4 frag(v2f i):SV_Target{
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));

            float3 worldPos = _WorldSpaceCameraPos + linearDepth*i.ray.xyz;

            float2 speed = _Time.y*float2(_FogXSpeed,_FogYSpeed);
            float noise = (tex2D(_NoiseTexture,i.uv+speed).r - 0.5)*_NoiseAmount;//采样噪声纹理 对采样坐标进行偏移 

            float fogDensity = (_FogEnd - worldPos.y)/(_FogEnd - _FogStart);//计算雾效系数
            fogDensity = saturate(fogDensity *_FogDensity*(1+noise));//雾效系数 乘以浓度系数 乘以噪声 不加一 雾效很稀
            fixed4 finalcolor = tex2D(_MainTex,i.uv);
            finalcolor.rgb = lerp(finalcolor.rgb,_FogColor.rgb,fogDensity);
            return finalcolor;
        }
        ENDCG
        Pass
        {
            ZTest Always Cull Off ZWrite Off 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
