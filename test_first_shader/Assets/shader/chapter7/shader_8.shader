// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/shader_8"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20.0
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : TEXCOORD0;
            };

            struct v2f
            {
               float4 pos:SV_POSITION;
               float3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
            };

       

            v2f vert (appdata v)//phong 光照模型
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//模型坐标转换到裁剪空间
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);//法线转换到世界坐标
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//模型坐标转换世界坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
              fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光
              fixed3 worldNormal = normalize(i.worldNormal);//法线归一化
              fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//获取光源向量
              fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));//计算漫反射
              fixed3 refectDir = normalize(reflect(-worldLightDir,worldNormal));//反射向量
              fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);//视角方向
              fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(refectDir,viewDir)),_Gloss);//计算高光反射
              return fixed4(ambient+diffuse+specular,1.0);

            }
            ENDCG
        }
    }
}
