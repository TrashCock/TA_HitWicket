Shader "D7/BGTemp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseTex ("BaseTexture", 2D) = "white" {}
        _SkyTex ("SkyTexture", 2D) = "white" {}
        _Step1("step1",float) = 0
        _Step2("Step2",float) = 0
        _BaseMaskPos("BasePosition",float) = 0
        _SkyMaskPos("SkyPosition",float) = 0

        _ScrollSpeeds("Scroll Speeds", vector) = (-5.0, -20.0, 0, 0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _BaseTex;
            sampler2D _SkyTex;
            float4 _MainTex_ST;
            float4 _SkyTex_ST;
            float _SkyMaskPos;
            float _BaseMaskPos;
            float _Step1;
            float _Step2;

            float4 _ScrollSpeeds;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.uv1, _SkyTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float2 BaseUV = float2(i.uv.x,i.uv.y);
                float2 SkyUV = float2(i.uv.x*_Time.x,i.uv.y);
                fixed4 col = tex2D(_MainTex,BaseUV);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //float distance = i.uv.y *2-1;

                half2 center = half2(0.5, 0.5);

                float baseMask = length(i.uv.y *.5f+ _BaseMaskPos);
                float skyMask = length(i.uv1.y +_SkyMaskPos);
                float basemask = smoothstep(_Step1, _Step2, baseMask);
                float skymask = smoothstep(_Step1, _Step2, skyMask);

                float2 skyUV = float2(i.uv.x, skymask);

                //float4 skyCol = tex2D(_SkyTex, i.uv1*2-1);
                half2 polar = float2(atan2(i.uv1.y, i.uv1.x) / (2.0f * 3.141592653589f), length(i.uv1) * 0.5f);

                half2 skyUVs = polar * _SkyTex_ST.xy;
                skyUVs += _ScrollSpeeds.zw * _Time.x;

                float4 skyCol = tex2D(_SkyTex,skyUVs+_SkyMaskPos);
                float4 baseCol = tex2D(_BaseTex,i.uv);

                col.rgb = lerp(col, skyCol, skymask);
                col.rgb = lerp(col, baseCol, basemask * baseCol.a);
                return col;
            }
            ENDCG
        }
    }
}
