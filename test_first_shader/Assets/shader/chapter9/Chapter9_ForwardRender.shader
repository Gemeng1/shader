﻿// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/Chapter9_ForwardRender"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color ) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode"="ForwardBase" }//计算基础的光源 平行光 没有光照衰减
            CGPROGRAM
            #pragma multi_compile_fwdbase   //光照衰减 
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
               float4 pos:SV_POSITION;
               float3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir+viewDir);
                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                fixed atten = 1.0;//衰减值
                return fixed4(ambient+(diffuse+specular)*atten,1.0);
            }
            ENDCG
        }

        Pass 
        {
            Tags{"LightMode" = "ForwardAdd"}//渲染其他的光源 例如点光源 聚光点 等等 每个光源都会执行一次这个pass
            Blend One One
            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct  a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                #ifdef USEING_DIRECTIONAL_LIGHT
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz-i.worldPos.xyz);
                #endif

                fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir+viewDir);
                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    #if defined(POINT)
                        float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1.0)).xyz;
                        fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined(SPOT)
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;   
                    #endif
                #endif

                return fixed4((diffuse+specular)*atten,1.0);
            }

            ENDCG

        }
    }
    FallBack "Specular"
}
