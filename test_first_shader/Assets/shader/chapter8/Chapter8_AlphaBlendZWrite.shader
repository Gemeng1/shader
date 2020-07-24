﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Chapter8_AlphaBlendZWrite"
{
    Properties
    {
        _Color ("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale ("Alpha Scale",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Pass
        {
            ZWrite on//逐像素 深度写入
            ColorMask 0//不写入任何颜色到颜色缓冲中
        }

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float3 texcoord:TEXCOORD0;
            };

            struct v2f
            {
               float4 pos:SV_POSITION;
               float3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
               float2 uv:TEXCOORD2;
            };

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed3 worldNormal = normalize(i.worldNormal);

               fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

               fixed4 texColor = tex2D(_MainTex,i.uv);

               fixed3 albedo = texColor.rgb * _Color.rgb;

               fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

               fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir));

               return fixed4(ambient+diffuse,texColor.a*_AlphaScale);
            }
            ENDCG
        }
    }

    //Fallback "Diffuse"
}
