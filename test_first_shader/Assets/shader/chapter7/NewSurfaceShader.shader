Shader "Custom/NewSurfaceShader"
{
    Properties{
        _Color("Color Tint",Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader{
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _Color;

            struct a2v {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                fixed4 color:COLOR0;
            };
         
            v2f vert(appdata_full v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = fixed4(v.normal*0.5+fixed3(0.5,0.5,0.5),1.0);
                o.color = fixed4(v.tangent*0.5 +fixed3(0.5,0.5,0.5),1.0);
                fixed3 binnormal = cross(v.normal,v.tangent)*v.tangent.w;
                o.color = fixed4(binnormal*0.5+fixed3(0.5,0.5,0.5),1.0);
                o.color = fixed4(v.texcoord.xy,0.0,1.0);
                o.color = fixed4(v.texcoord1.xy,0.0,1.0);
                o.color = frac(v.texcoord);
                if(any(saturate(v.texcoord)-v.texcoord)){
                    o.color.b = 0.5;
                }
                o.color = frac(v.texcoord1);
                if(any(saturate(v.texcoord1)-v.texcoord1)){
                    o.color.b = 0.5;
                }
                return o;
            }

            fixed4 frag(v2f f):SV_Target{
                //fixed3 c = f.color;
                //c *= _Color.rgb;
                //return fixed4(c,1.0);
                return f.color;
            }
            
            ENDCG
        }
    }
}
