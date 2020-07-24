Shader "Unlit/chapter13-ZTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HighLightingColor("HighLight Color",Color) = (1,1,1,1)
        _Threshold("Threshold ",Float) = 2.0
        _MainColor("MainColor",Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "Queue "="Transparent" "RenderType"="Transparent" }

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            Blend  SrcAlpha OneMinusSrcAlpha 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 projPos:TEXCOORD0;
                float3 viewPos:TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            uniform sampler2D_float _CameraDepthTexture;



            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;
            float _Threshold;
            fixed4 _HighLightingColor;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos(o.pos);
                o.viewPos = UnityObjectToViewPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 finalColor = _MainColor;
                float screenZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));//获得线性的深度
                float partZ = -i.viewPos.z;//因为摄像机的z方向 反方向 需要取反。获得正方向
                float diff = min(abs(screenZ-partZ)/_Threshold,1.0);//（通过当前像素点摄像机的深度值 减去 当想像素的深度 ）除以一个系数 个人理解为 相交的着色 宽度
                finalColor = lerp(_HighLightingColor,_MainColor,diff)*tex2D(_MainTex,i.uv);//先和光亮颜色和纹理颜色 做差值 然后和当前纹理采样颜色做混合
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"//通过投影获得 深度纹理 
}
