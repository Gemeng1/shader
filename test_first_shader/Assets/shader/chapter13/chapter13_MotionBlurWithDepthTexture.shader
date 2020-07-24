Shader "Unlit/chapter13_MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size",Float) = 0.5
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D  _MainTex;
        half4 _MainTex_TexelSize;
        half _BlurSize;
        sampler2D _CameraDepthTexture;
        float4x4 _OldMatrix;
        float4x4 _CurMatrixInverse;

        struct v2f
        {
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD0;
            half2 uv_depth:TEXCOORD1; 
        };

        v2f vert(appdata_img v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP//理解 如果原点时左上角 说明时DX opengl 是左下角。DX 如果反转 否则是反的
            if(_MainTex_TexelSize.y < 0)
               o.uv_depth.y  = 1- o.uv_depth.y;
            #endif
            return o;
        }

        fixed4 frag(v2f i):SV_Target{
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);//获取当前纹理 摄像机的深度值
            float4 H = float4(i.uv.x*2+1,i.uv.y*2+1,d*2+1,1.0);//将H回归到NDC xyz 均为[-1,1] //重建每个像素在世界空间的位置
            
            float4 c = mul(_CurMatrixInverse,H);//将这个点 变化
            float4 worldPos = c/c.w;

            float4 currPos = H;

            float4 oldPos = mul(_OldMatrix,worldPos);

            oldPos /= oldPos.w;

            float speed = (currPos - oldPos)/2.0f;

            float2 uv = i.uv;
            float4 color = tex2D(_MainTex,uv);
            uv += speed * _BlurSize;//累加邻近的像素的采样纹理 

            for (int i = 1; i < 3; i++,uv += speed * _BlurSize)
            {
                color += tex2D(_MainTex,uv);
            }
            color /= 3;//获得一个平均值
            return fixed4(color.rgb,1.0);
        }
        ENDCG

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
