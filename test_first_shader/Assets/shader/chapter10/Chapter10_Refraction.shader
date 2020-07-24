Shader "Unlit/Chapter10_Refraction"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _RefractColor("Refraction Color",Color) = (1,1,1,1)
        _RefractAmount("Refraction Amount",Range(0,1)) = 1
        _RefractRatio("Refraction Ratio",Range(0.1,1)) = 0.5//空气折射率 和 介质折射率的 比率
        _Cubemap("Refraction Cubemap",Cube) = "_Skybox" {}
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
                fixed3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4)  
            };

            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
            samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefr = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);//获得折射方向 入射方向。法线 折射率
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

                fixed3 refraction = texCUBE(_Cubemap,i.worldRefr).rgb * _RefractColor.rgb;//通过折射来采样

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                fixed3 color = ambient + lerp(diffuse,refraction,_RefractAmount)*atten;

                return fixed4(color,1.0);
                
            }
            ENDCG
        }
    }
    FallBack "Reflective/VertexLit"
}
