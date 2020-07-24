Shader "Unlit/WaterShader"
{
    Properties
    {
        _LiquidColor("LiquidColor",Color) = (1,1,1,1)
        _NoiseTex("Noise Texture",2D) = "white"{}
        _FillAmount("Fill Amount",Range(-10,10)) = 0.0
        [HideInInspector]_WobbleX("WobbleX",Range(-1,1)) = 0.0
        [HideInInspector]_WobbleZ("WobbleZ",Range(-1,1)) = 0.0
        _LiquidTopColor("Liquid Top Color",Color) = (1,1,1,1)
        _LiquidFoamColor("Liquid Foam Color",Color) = (1,1,1,1)
        _FoamLineWidth("Liquid Foam Line Width",Range(0,0.1)) = 0.0
        _LiquidRimColor("Liquid Rim Color",Color) = (1,1,1,1)
        _LiquidRimPower("Liquid Rim Power",Range(0,10)) = 0.0
        _LiquidRimIntensity("Liquid Rim Intensity",Range(0.0,3.0)) = 1.0

        _BottleColor("Bottle Color",Color) = (0.5,0.5,0.5,1)
        _BottleThickness("Bottle Thickness",Range(0,1)) = 0.1

        _BottleRimColor("Bottle Rim Color",Color) = (1,1,1,1)
        _BottleRimPower("Bottle Rim Power",Range(0,10)) = 0.0
        _BottleRimIntensity("Bottle Rim Intensity",Range(0.0,3.0)) = 1.0

        _BottleSpecular("Bottle Specular",Range(0,1)) = 0.5
        _BottleGloss("BottleGloss",Range(0,1)) = 0.5


    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "DisableBaching" = "True"}

        Pass
        {
            Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
            ZWrite On 
            Cull Off
            AlphaToMask On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
                float3 viewDir:TEXCOORD1;
                float3 normal:TEXCOORD2;
                float  fillEdge:TEXCOORD3;
                
            };

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _FillAmount,_WobbleX,_WobbleZ;
            float4 _LiquidColor,_LiquidRimColor,_LiquidFoamColor,_LiquidTopColor;
            float _FoamLineWidth,_LiquidRimPower,_LiquidRimIntensity;

            float4 RotateAroundYinDegress(float4 vertex,float degrees)
            {
                float alpha = degrees * UNITY_PI/180;
                float sina,cosa;
                sincos(alpha,sina,cosa);
                float2x2 m = float2x2(cosa,sina,-sina,cosa);
                return float4(vertex.yz,mul(m,vertex.xz)).xyzw;
            }

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex.xyz);
                float3 worldPosX = RotateAroundYinDegress(float4(worldPos,0),360);
                float3 worldPosZ = float3(worldPosX.y,worldPosX.z,worldPosX.x);

                float3 worldPosAdjusted = worldPos + (worldPosX*_WobbleX)+(worldPosZ*_WobbleZ);
                o.fillEdge = worldPosAdjusted.y + _FillAmount;

                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i,fixed facing:VFACE) : SV_Target
            {
            
                fixed4 col = tex2D(_NoiseTex,i.uv)*_LiquidColor;

                float dotProduct = 1-pow(dot(i.normal,i.viewDir),_LiquidRimPower);
                float4 RimResult = _LiquidRimColor*smoothstep(0.5,1.0,dotProduct)*_LiquidRimIntensity;

                float4 foam = step(i.fillEdge,0.5)-step(i.fillEdge,(0.5 - _FoamLineWidth));

                float4 foamColor = foam*_LiquidFoamColor;

                float4 result = step(i.fillEdge,0.5)-foam;
                float4 resultColor = result*col;

                float4 finalResult = resultColor + foamColor;

                finalResult.rgb += RimResult;

                float4 topColor = _LiquidTopColor*(foam+result);


                return facing > 0?finalResult:topColor;
            }
            ENDCG
        }

        Pass {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex:POSITION;
                float2 texcoord:TEXCOORD0;
                float3 normal:NORMAL; 
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 viewDir:TEXCOORD0;
                float3 normal:TEXCOORD1; 
                float2 uv:TEXCOORD2;
                float3 viewDirWorld:TEXCOORD3;
                float3 lightDir:TEXCOORD4; 
            };

            float4 _BottleColor,_BottleRimColor;
            float _BottleThickness,_BottleRimPower,_BottleRimIntensity,_BottleSpecular,_BottleGloss;

            v2f vert(a2v v){
                v2f o;
                v.vertex.xyz += _BottleThickness*v.normal;

                o.pos = UnityObjectToClipPos(v.vertex);


                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.normal = v.normal;

                float4 posWorld = mul(unity_ObjectToWorld,v.vertex.xyz);
                o.viewDirWorld = normalize(_WorldSpaceCameraPos.xyz- posWorld.xyz);
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
                return o;
            }

            fixed4 frag(v2f i,fixed facing:VFACE):SV_Target{
                float3 normalDir = normalize(UnityObjectToWorldNormal(i.normal));
                
                float specularPow = exp2((1- _BottleGloss)*10.0+1.0);
                fixed4 specularColor = fixed4(_BottleSpecular,_BottleSpecular,_BottleSpecular,_BottleSpecular);

                float3 halfVector = normalize(i.lightDir+i.viewDirWorld);
                fixed4 spacularCol = pow(saturate(dot(halfVector,normalDir)),specularPow)*specularColor;

                float dotProduct = 1- pow(dot(i.normal,i.viewDir),_BottleRimPower);
                fixed4 RimCol = _BottleRimColor*smoothstep(0.5,1.0,dotProduct);

                fixed4 finalCol = RimCol + _BottleColor +spacularCol;
                return finalCol;
            }
            ENDCG
        }
    }
}
