Shader "Unlit/shader_9"
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
            float  _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
               float4 pos:SV_POSITION;
               float3 WorldNormal:TEXCOORD0; 
               float3 WorldPos:TEXCOORD1;
            };

            v2f vert (a2v v)//BlinnPhong
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.WorldNormal = UnityObjectToWorldNormal(v.normal);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = normalize(i.WorldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.WorldPos));
                fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
                fixed3 viewDir  = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                fixed3 halfDir = normalize(worldLightDir+viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb*pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
    }
}
