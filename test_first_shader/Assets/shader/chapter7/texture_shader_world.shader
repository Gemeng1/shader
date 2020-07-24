// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/texture_shader_world"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
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

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float4 tangent:TEXCOORD0;
                float4 texcoord:TEXCOORD1;

            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 uv:TEXCOORD0;
                float4 TtoW0:TEXCOORD1;
                float4 TtoW1:TEXCOORD2;
                float4 TtoW2:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//转换到裁剪空间的 坐标
                o.uv.xy = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;//计算主纹理的uv坐标
                o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy+_BumpMap_ST.zw;//计算法线纹理的uv坐标

                float3 wordPos = mul(unity_ObjectToWorld,v.vertex).xyz;//w 转换到世界空间的坐标
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//z 转换世界空间的发现
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);//x 转换世界空间的 切线
                fixed3 worlfBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//y 副切线 

                o.TtoW0 = float4(worldTangent.x,worlfBinormal.x,worldNormal.x,wordPos.x);
                o.TtoW1 = float4(worldTangent.y,worlfBinormal.y,worldNormal.y,wordPos.y);
                o.TtoW2 = float4(worldTangent.z,worlfBinormal.z,worldNormal.z,wordPos.z);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
               fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
               fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

               fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
               bump.xy *= _BumpScale;
               bump.z = sqrt(1-saturate(dot(bump.xy,bump.xy)));
               bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

               fixed3 albedo = tex2D(_MainTex,i.uv.xy);
               fixed3 amibent = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
               fixed3 diffuse = _LightColor0.rgb*albedo*saturate(dot(bump,lightDir));
               fixed3 halfDir = normalize(lightDir+viewDir);
               fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(bump,halfDir)),_Gloss);
               return fixed4(amibent+diffuse+specular,1.0);
            }
            ENDCG
        }
    }
}
