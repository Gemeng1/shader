Shader "Unlit/Chapter10_Fresnel"//菲涅尔反射
{
    Properties
    {
        _Color("Color",Color ) = (1,1,1,1)
        _FresnelScale("fresnel scale",Range(0,1)) = 0.5
        _Cubemap("Cube Map",Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
  
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            float4 _Color;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);//通过 reflect  参数 入射方向 法线 计算出反射方向
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldNormal = normalize(i.worldNormal);
               fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
               fixed3 worldViewDir = normalize(i.worldViewDir);

               fixed3 ambinet = UNITY_LIGHTMODEL_AMBIENT.xyz;

               fixed3 reflectColor = texCUBE(_Cubemap,i.worldRefl).rgb;//通过反射方向 获得对应的map纹理

               //混合 漫反射光照 和反射光照 一些也会吧fresnel 直接和反射光照相乘后叠加到漫反射光照上 实现边缘光照效果
               fixed fresnel = _FresnelScale + (1+_FresnelScale)*pow((1 - dot(worldViewDir,worldNormal)),5);

               fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal,worldLightDir));//计算漫反射

               UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//通过引擎获得对应的光照衰减

               fixed3 color = ambinet+lerp(diffuse,reflectColor,saturate(fresnel))*atten;

               return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
