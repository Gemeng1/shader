Shader "Unlit/chapter13_FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogDensity("Fog Density",Float) = 1.0
        _FogColor("Fog Color",Color  ) = (1,1,1,1)
        _FogStart("Fog Start",Float) = 0.0
        _FogEnd("Fog End",Float) = 2.0
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            half4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            half _FogDensity;
            fixed4 _FogColor;
            float _FogStart;
            float _FogEnd;
            float4x4 _RayMatrix;
    
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0 ;
                float2 uv_depth:TEXCOORD1 ;
                float4 ray:TEXCOORD2 ;
                
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;
                
                //根据原点是 0.0 点 左下角为原点 中心点为[0.5,0.5] 判读该定点 属于那块区域 在使用对应的射线

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

            fixed4 frag(v2f i):SV_Target {
                float linerdepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));//获取当前线性深度值[-1,1]
                float3 worldPos = _WorldSpaceCameraPos + linerdepth*i.ray.xyz;//通过射线算出世界坐标

                float fogDensity = (_FogEnd - worldPos.y)/(_FogEnd - _FogStart);//算出无效系数 公式所得 f = （H(end) - y）/(H(end) - H(start))  y 是世界空间下的高度 H(start) H(end) 影响雾效的起始高度和终止高度

                float density = saturate(fogDensity*_FogDensity);//雾效系数 和雾浓度相乘 最小为1

                fixed4 color = tex2D(_MainTex,i.uv);

                color.rgb = lerp(color.rgb,_FogColor.rgb,density);//插值
                return color;
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
    FallBack Off
}
