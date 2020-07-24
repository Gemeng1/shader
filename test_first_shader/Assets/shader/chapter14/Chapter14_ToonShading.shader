Shader "Unlit/Chapter14_ToonShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color  ) = (1,1,1,1)
        _Ramp("Ramp",2D) = "white" {}
        _Outline("Outline",Range(0,1)) = 0.1
        _OutlineColor("Outline Color",Color) =(0,0,0,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _SpecularScale("Specular Scale",Range(0,0.1)) = 0.01
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "Queue" = "Geometry"}
        Pass
        {
            NAME "OUTLINE"//描边
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Outline;
            fixed4 _OutlineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;
                float4 pos = float4(UnityObjectToViewPos(v.vertex),1.0);//模型空间顶点变换到观察空间下
                float3 normal = mul((float3x3)UNITY_MATRIX_MV,v.normal);//将法线变换到观察空间下
                normal.z = -0.5;//将z分量设置一个固定值
                pos = pos + float4(normalize(normal),1.0)*_Outline;//算坐标 归一化法线 乘以描边宽度
                o.pos = mul(UNITY_MATRIX_P,pos);//将坐标变换到剪裁空间
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(_OutlineColor.rgb,1.0);
            }
            ENDCG
        }
         
        Pass{


            Tags {"LightMode" = "ForwardBase"}

            Cull Back
            CGPROGRAM
          
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase //使光照正常使用

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D  _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale; 

            struct a2v
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
             {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0; 
                float3 worldPos:TEXCOORD1; 
                float3 worldNormal:TEXCOORD2; 
                SHADOW_COORDS(3)
             };

             v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);//阴影采样
                return o;
             } 

             fixed4 frag(v2f i):SV_Target{
                fixed3 WorldNormal = normalize(i.worldNormal);
                fixed3 WorldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 WorldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 WorldHalf = normalize(WorldLightDir+WorldViewDir);//半兰伯特光照

                fixed4 col = tex2D(_MainTex,i.uv);
                fixed3 albedo = col.rgb *_Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//获取阴影 光照衰减

                fixed diff = dot(WorldNormal,WorldLightDir);
                diff = (diff*0.5+0.5)*atten;//半兰伯特光照

                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp,float2(diff,diff)).rgb;

                fixed spec = dot(WorldNormal,WorldHalf);//特殊的高光反射
                fixed w = fwidth(spec)*2.0;//对高光区域的边界做抗锯齿处理
                fixed3 specular = _Specular.rgb*lerp(0,1,smoothstep(-w,w,spec+_SpecularScale-1))*step(0.0001,_SpecularScale);//_SpecularScale 等于0 完全消除高光反射
                return fixed4(ambient+diffuse+specular,1.0);

             }
            ENDCG

        }
    }
    FallBack "Diffuse"
}
