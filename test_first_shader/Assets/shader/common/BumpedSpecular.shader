Shader "Unlit/BumpedSpecular"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map",2D) = "bump" {}
        _Specular ("specular Color ",Color) = (1,1,1,1)
        _Gloss ("gloss",Range(8.0,256)) = 20
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
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 Ttow0:TEXCOORD1;
                float4 Ttow1:TEXCOORD2;
                float4 Ttow2:TEXCOORD3;
                SHADOW_COORDS(4)
            };


            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                
                // TANGENT_SPACE_ROTATION;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.vertex);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                o.Ttow0 = float4(worldTangent.x,worldTangent.x,worldNormal.x,worldPos.x);
                o.Ttow1 = float4(worldTangent.y,worldTangent.y,worldNormal.y,worldPos.y);
                o.Ttow2 = float4(worldTangent.z,worldTangent.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.Ttow0.w,i.Ttow1.w,i.Ttow2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump = normalize(half3(dot(i.Ttow0.xyz,bump),dot(i.Ttow1.xyz,bump),dot(i.Ttow2.xyz,bump)));

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb*_Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,worldLightDir));

                fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump,halfDir)),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                return fixed4(ambient+(diffuse+specular)*atten,1.0);
                
            }
            ENDCG
        }

        Pass 
        {
            Tags{"LightMode"="ForwardAdd"}

            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdadd

            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD0; 
                
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 uv:TEXCOORD0;
                float4 Ttw0:TEXCOORD1;
                float4 Ttw1:TEXCOORD2;
                float4 Ttw2:TEXCOORD3;
                SHADOW_COORDS(4)
                
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float4 _Specular;
            float _Gloss;


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy+_BumpMap_ST.zw;

                //TANGENT_SPACE_ROTATION;

                fixed3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                o.Ttw0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.Ttw1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.Ttw2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o);
                return o;

            }

            fixed4 frag (v2f i):SV_Target
            {
                float3 worldPos = float3(i.Ttw0.w,i.Ttw1.w,i.Ttw2.w);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump = normalize(half3(dot(i.Ttw0.xyz,bump),dot(i.Ttw1.xyz,bump),dot(i.Ttw2.xyz,bump)));

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb*_Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,worldLightDir));

                fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(bump,halfDir)),_Gloss);
                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                return fixed4((diffuse+specular)*atten,1.0);

            }

            ENDCG

        }
    }

    FallBack "Specular"
}
