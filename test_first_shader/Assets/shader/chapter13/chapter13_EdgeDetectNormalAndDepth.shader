Shader "Unlit/chapter13_EdgeDetectNormalAndDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeOnly("Edge Only",Float) = 0.0
        _EdgeColor("Edge Color",Color  ) = (0,0,0,1)
        _BackgroundColor("Background Color ",Color  ) = (1,1,1,1)
        _SampleDistance("Sample Distance",Float) = 1.0
        _Sensitivity("Sensitivity",Vector) = (1,1,1,1)
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            sampler2D  _MainTex;
            half4 _MainTex_TexelSize;
            half _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;
            float _SampleDistance;
            half4 _Sensitivity;
            sampler2D  _CameraDepthNormalsTexture; //深度+法线纹理。xy代表发现 zw代表深度值
            struct v2f
            {
                float4 pos:SV_POSITION;
                half2 uv[5]:TEXCOORD0 ; 
                
            };

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 uv = v.texcoord;
                o.uv[0] = uv;
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                    uv.y = 1- uv.y;
                #endif
                o.uv[1] = uv + _MainTex_TexelSize.xy*half2(1,1)*_SampleDistance;//采样该纹理四周的纹理坐标 Roberts 算子
                o.uv[2] = uv + _MainTex_TexelSize.xy*half2(-1,-1)*_SampleDistance;
                o.uv[3] = uv + _MainTex_TexelSize.xy*half2(-1,1)*_SampleDistance;
                o.uv[4] = uv + _MainTex_TexelSize.xy*half2(1,-1)*_SampleDistance;

                return  o;
            }

            half CheckSame(half4 sampler1,half4 sampler2){
                half2 sampler1_normal = sampler1.xy;//法线不解码 因为不在乎是不是真实法线。只要比较两个采样值的差异度
                float sampler1_depth = DecodeFloatRG(sampler1.zw);//解码深度值

                half2 sampler2_normal = sampler2.xy;
                float sampler2_depth = DecodeFloatRG(sampler2.zw);

                half2 diffentNormal = abs(sampler1_normal - sampler2_normal)*_Sensitivity.x;//_Sensitivity 灵敏度

                int isSame_normal = (diffentNormal.x + diffentNormal.y) < 0.1;

                float diffentDepth = abs(sampler1_depth - sampler2_depth)*_Sensitivity.y;

                int isSame_depth = diffentDepth < 0.1* sampler1_depth;

                return isSame_normal*isSame_depth ? 1.0:0.0;
            }

            fixed4 frag(v2f i):SV_Target{
                half4 sampler1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);//采样纹理
                half4 sampler2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
                half4 sampler3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
                half4 sampler4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);

                half edge = 1.0;
                edge *= CheckSame(sampler1,sampler2);
                edge *= CheckSame(sampler3,sampler4);

                fixed4 mainColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[0]),edge);//差值
                fixed4 background = lerp(_EdgeColor,_BackgroundColor,edge);
                return lerp(mainColor,background,_EdgeOnly);

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
