Shader "Unlit/Chapter10_GlassRefraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map",2D) = "bump" {}//介质的反射纹理
        _CubeMap ("Eviroment Map",Cube) = "_Skybox" {}//模拟反射的环境纹理
        _Distortion ("Distortion",Range(0,100)) = 10//模拟折射的扭曲程度
        _RefractAmount ("Refract Amount",Range(0.0,1)) = 1//折射强度
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" } //显示透明的 要修改渲染队列
        GrabPass{"_RefractionTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 Ttw0 : TEXCOORD2;
                float4 Ttw1 : TEXCOORD3;
                float4 Ttw2 : TEXCOORD4;
            };

            

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);//抓去屏幕图像的采样坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//通过发现和切线算出新发现 w 分量来确定方向

                o.Ttw0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.Ttw1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.Ttw2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.Ttw0.w,i.Ttw1.w,i.Ttw2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));

                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;

                i.scrPos.xy = offset*i.scrPos.z + i.scrPos.xy;

                fixed3 refractColor = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;

                bump = normalize(half3(dot(i.Ttw0.xyz,bump),dot(i.Ttw1.xyz,bump),dot(i.Ttw2.xyz,bump)));

                fixed3 reflectDir = reflect(-worldViewDir,bump);

                fixed4 texColor = tex2D(_MainTex,i.uv.xy);

                fixed3 reflectColor = texCUBE(_CubeMap,reflectDir).rgb * texColor.rgb;

                fixed3 finalColor = reflectColor *(1 - _RefractAmount) + refractColor * _RefractAmount;

                return fixed4(finalColor,1);

            }
            ENDCG
        }
    }
    // FallBack "Diffuse"
}
