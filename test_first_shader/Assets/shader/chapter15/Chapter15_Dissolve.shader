Shader "Unlit/Chapter15_Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BurnAmount("Burn Amount",Range(0.0,1.0)) = 0.0//消融程度
        _LineWidth("Burn Line Width",Range(0.0,0.2)) = 0.1//控制模拟着烧效果的线宽
        _BumpMap("Normal Map",2D) = "bump"{}//法线纹理
        _BurnFirstColor("Burn First Color",Color) = (1,0,0,1)//火焰边缘的颜色
        _BurnSecondColor("Burn Second Color",Color) = (1,0,0,1)//火焰边缘的颜色
        _BurnMap("Burn Map",2D) = "white"{}//噪声纹理
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpTex : TEXCOORD1;
                float2 uvBurnTex : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5) 
            };

            sampler2D _MainTex;
            fixed _BurnAmount;
            fixed _LineWidth;
            sampler2D  _BumpMap;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;

            float4 _MainTex_ST;
            float4 _BumpMap_ST;
            float4 _BurnMap_ST;


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);//获取对于的纹理坐标
                o.uvBumpTex = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uvBurnTex = TRANSFORM_TEX(v.texcoord,_BurnMap);

                TANGENT_SPACE_ROTATION;//获取切线变换矩阵
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;//将光源方向从模型空间转换到切线空间
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//为得到正确的阴影 将顶点 从模型空间转换到世界空间

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap,i.uvBurnTex).rgb;//采样噪声纹理

                clip(burn.r - _BurnAmount);//通过r 值 减去 消融程度 或判断当前片元是否裁剪

                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uvBumpTex));//获得切线空间下的法线

                fixed3 albedo = tex2D(_MainTex,i.uvMainTex).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光

                fixed3 diffuse = _LightColor0.rgb*albedo*saturate(dot(tangentNormal,tangentLightDir));//计算漫反射

                fixed t = 1- smoothstep(0.0,_LineWidth,burn.r - _BurnAmount);//将火焰宽度 在【0._LineWidth】
                fixed3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t);//插值 火焰颜色
                burnColor = pow(burnColor,5);//颜色加重

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                fixed3 finalColor = lerp(ambient+diffuse*atten,burnColor,t*step(0.0001,_BurnAmount));

                return fixed4(finalColor,1.0);
           
            }
            ENDCG
        }

        Pass {
            Tags{"LightMode" = "ShadowCaster"}//自定义阴影pass

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 uvBurnMap:TEXCOORD0; 
                
            };

            v2f vert( appdata_base v){
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BumpMap);
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 burn = tex2D(_BurnMap,i.uvBurnMap).rgb;
                clip(burn.r - _BurnAmount);//添加噪声纹理 裁剪
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
}
