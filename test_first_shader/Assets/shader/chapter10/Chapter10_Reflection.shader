Shader "Unlit/Chapter10_Reflection"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _ReflectColor("reflect color",Color) = (1,1,1,1)//控制反射的颜色
        _ReflectAmount("reflect Amount",Range(0,1)) = 1//反射程度
        _CubeMap("reflect cubemap",Cube) = "_Skybox"{}//模拟反射的环境映射纹理

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"} //都是默认设置参数

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;
            samplerCUBE _CubeMap;

            struct  a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;

            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldPos:TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldViewDir:TEXCOORD2;
                fixed3 worldRefl:TEXCOORD3;//反射方向没有被归一化 因为采集纹理 只利用了方向 
                SHADOW_COORDS(4)

            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(i.worldNormal,worldLightDir));

                fixed3 reflection = texCUBE(_CubeMap,i.worldRefl).rgb * _ReflectColor.rgb;//利用反射方向来采集纹理

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//利用引擎的接口获得光照衰减

                fixed3 color = ambient + lerp(diffuse,reflection,_ReflectAmount)*atten;//利用_ReflectAmount 来混黑漫反射的颜色 和 反射颜色  lerp线性插值
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
