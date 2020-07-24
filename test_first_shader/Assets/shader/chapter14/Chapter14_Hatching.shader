Shader "Unlit/Chapter14_Hatching"
{
    Properties
    {
        _Color("Color",Color ) = (1,1,1,1)
        _TileFactor("Tile Factor",Float) = 1.0
        _Outline("Outline",Range(0,0.1)) = 0.01
        _OutlineColor("Outline Color",Color) = (0,0,0,1)
        _Hatch0("Hatch 0",2D) = "white"{}
        _Hatch1("Hatch 1",2D) = "white"{}
        _Hatch2("Hatch 2",2D) = "white"{}
        _Hatch3("Hatch 3",2D) = "white"{}
        _Hatch4("Hatch 4",2D) = "white"{}
        _Hatch5("Hatch 5",2D) = "white"{}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        UsePass "Unlit/Chapter14_ToonShading/OUTLINE"

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;



            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed3 hatchWeight0:TEXCOORD1;
                fixed3 hatchWeight1:TEXCOORD2;
                float3 worldPos:TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord*_TileFactor;
                
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                fixed diff = max(0,dot(worldLightDir,worldNormal));

                o.hatchWeight0 = fixed3(0,0,0);//初始化权重。六张纹理六个权重
                o.hatchWeight1 = fixed3(0,0,0);

                float hatchFactor = diff * 7.0;//扩大七倍

                if(hatchFactor > 6.0){//七个分段

                }else if(hatchFactor > 5.0){
                    o.hatchWeight0.x = hatchFactor - 5.0;
                }else if(hatchFactor > 4.0){
                    o.hatchWeight0.x = hatchFactor - 4.0;
                    o.hatchWeight0.y = 1.0 - o.hatchWeight0.x;
                }else if(hatchFactor > 3.0){
                    o.hatchWeight0.y = hatchFactor - 3.0;
                    o.hatchWeight0.z = 1.0- o.hatchWeight0.y;
                }else if(hatchFactor > 2.0){
                    o.hatchWeight0.z = hatchFactor - 2.0;
                    o.hatchWeight1.x = 1.0 - o.hatchWeight0.z;
                }else if(hatchFactor > 1.0){
                    o.hatchWeight1.x = hatchFactor - 1.0;
                    o.hatchWeight1.y = 1.0- o.hatchWeight1.x;
                }else{
                    o.hatchWeight1.y = hatchFactor;
                    o.hatchWeight1.z = 1.0 - o.hatchWeight1.y;
                }

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 hatchColor = fixed4(0,0,0,0);
                hatchColor += tex2D(_Hatch0,i.uv)*i.hatchWeight0.x;
                hatchColor += tex2D(_Hatch1,i.uv)*i.hatchWeight0.y;
                hatchColor += tex2D(_Hatch2,i.uv)*i.hatchWeight0.z;
                hatchColor += tex2D(_Hatch3,i.uv)*i.hatchWeight1.x;
                hatchColor += tex2D(_Hatch4,i.uv)*i.hatchWeight1.y;
                hatchColor += tex2D(_Hatch5,i.uv)*i.hatchWeight1.z;

                //用白色去减这这个点在的权重，因为剩下的位置都得是白色
                hatchColor += fixed4(1,1,1,1)*(1-i.hatchWeight0.x-i.hatchWeight0.y-i.hatchWeight0.z-i.hatchWeight1.x-i.hatchWeight1.y-i.hatchWeight1.z);//这个必须加 要不然会有很多黑的区域 

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(hatchColor.rgb * _Color.rgb*atten,1.0);
            }
            ENDCG
        }
    }
}
