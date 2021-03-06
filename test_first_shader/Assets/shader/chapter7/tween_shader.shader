﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/tween_shader"
{
    Properties
    {  
        _Color ("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss ("Gloss",Range(8.0,256)) = 20
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
                float4 texcoord:TEXCOORD0;

            };

            struct v2f
            {
               float4 pos:SV_POSITION;
               float3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
               float2 uv:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldNormal = normalize(i.worldNormal);
               fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

               fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

               fixed halfLambert = 0.5*dot(worldNormal,worldLightDir)+0.5;//半兰伯特
               fixed3 diffuseColor = tex2D(_MainTex,fixed2(halfLambert,halfLambert)).rgb*_Color.rgb;//半兰伯特 充当uv坐标 
               fixed3 diffuse = _LightColor0.rgb*diffuseColor;//*saturate(dot(worldNormal,worldLightDir));

               fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
               fixed3 halfDir = normalize(worldLightDir+viewDir);
               fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(worldNormal,halfDir)),_Gloss);
               
               return fixed4(ambient+diffuse+specular,1.0);
              
            }
            ENDCG
        }
    }
}
