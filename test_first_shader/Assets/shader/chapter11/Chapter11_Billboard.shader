Shader "Unlit/Chapter11_Billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color",Color ) = (1,1,1,1)
        _VerticalBillboarding("Vertical Billboarding",Range(0,1)) = 1
    }
    SubShader
    {
        Tags {"Queue" = "Transparent"  "IgnoreProjector" = "True" "RenderType"="Transparent" "DisableBatching" = "True" }
        

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull  Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _VerticalBillboarding;

            v2f vert (a2v v)
            {
                v2f o;
                float3 center = float3(0,0,0);//模拟锚点
                float3 viewDir = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));//将摄像机方向 转换到模型空间
                float3 normalDir = viewDir - center;//假设锚点是法线指向方向。算出发现方向
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1):float3(0,1,0);
                float3 rightDir = normalize(cross(upDir,normalDir));
                upDir = normalize(cross(normalDir,rightDir));

                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir*centerOffs.x+upDir*centerOffs.y+normalDir*centerOffs.z;
                o.pos = UnityObjectToClipPos(float4(localPos,1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= _Color.rgb;
                return col;
            }
            ENDCG
        }
    }
}
