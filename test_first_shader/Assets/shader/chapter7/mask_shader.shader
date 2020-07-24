Shader "Unlit/mask_shader"
{
    Properties
    {
        _Color ("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map",2D) = "bump"{}
        _BumpScale( "Bump Scale",Float) = 1.0
        _SpecularMask ("Specular Mask",2D) = "white" {}
        _SpecularScale ("Specular Scale",Float) = 1.0
        _Specular ("Specular",Color) = (1,1,1,1)
        _Gloss ("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
        LOD 100

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
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD0;

            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 lightDir:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };


            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;//三个纹理都用同一个纹理坐标
            sampler2D _BumpMap;
            float _BumpScale;//凹凸程度
            sampler2D _SpecularMask;
            float _SpecularScale;//遮罩强弱
            fixed4 _Specular;
            float _Gloss;
        

            v2f vert (a2v v)//切线空间下 用到了发现纹理
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target//blinnPhong
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;

                fixed3 diffuse = _LightColor0.rgb*albedo*saturate(dot(tangentNormal,tangentLightDir));

                fixed3 halfDir = normalize(tangentViewDir+tangentLightDir);

                fixed3 specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;//遮罩纹理 每个rgb分量都一样

                fixed3 specular = _LightColor0.rgb*_Specular.rbg*pow(saturate(dot(tangentNormal,halfDir)),_Gloss)*specularMask;

                return fixed4(ambient+diffuse+specular,1.0);




            }
            ENDCG
        }
    }
}
