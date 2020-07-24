Shader "Unlit/Chapter15_WaterWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color ) = (0,0.15,0.115,1)
        _WaveMap("Wave Map",2D) = "bump"{}
        _CubeMap("Environment Cubemap",Cube) = "_Skybox"{}
        _WaveXSpeed("Wave Horizontal Speed",Range(-0.1,0.1)) = 0.01
        _WaveYSpeed("Wave Vertical Speed",Range(-0.1,0.1)) = 0.01
        _Distortion("Distortion",Range(0,100)) = 10

    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Opaque" }
        GrabPass{"_RefractionTex"}

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 scrPos:TEXCOORD0;
                float4 uv:TEXCOORD1;
                float4 TtoW0:TEXCOORD2;
                float4 TtoW1:TEXCOORD3;
                float4 TtoW2:TEXCOORD4; 
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;

            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_WaveMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//将切线变换到世界空间中
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//计算出副切线

                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);

                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);

                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
               fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
               float2 speed = _Time.y*float2(_WaveXSpeed,_WaveYSpeed);//计算速度

               fixed3 bump1 = UnpackNormal(tex2D(_WaveMap,i.uv.zw+speed)).rgb;//UnpackNormal 对法线纹理采样 解码   获得正确的法线方向  对法线采样进行偏移
               fixed3 bump2 = UnpackNormal(tex2D(_WaveMap,i.uv.zw-speed)).rgb;
               fixed3 bump = normalize(bump1+bump2);

               float2 offset = bump.xy*_Distortion*_RefractionTex_TexelSize.xy;//屏幕图像的采样坐标进行偏移 

               i.scrPos.xy = offset*i.scrPos.z+i.scrPos.xy;//模拟深度越大越扭曲
               fixed3 refrCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;//折射采样

               bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));//把法线方向 从切线空间变换到世界空间下

               fixed4 texColor = tex2D(_MainTex,i.uv.xy);

               fixed3 reflDir = reflect(-viewDir,bump);//计算反射方向
               fixed3 reflCol = texCUBE(_CubeMap,reflDir).rgb*texColor.rgb*_Color.rgb;//采样反射纹理

               fixed fresnel = pow(1 - saturate(dot(viewDir,bump)),4);//菲涅尔定律

               fixed3 finalColor = reflCol*fresnel+refrCol*(1 - fresnel);//反射占比 加上折射占比

               return fixed4(finalColor,1.0);

               
            }
            ENDCG
        }
    }
}
