Shader "D7/TTOonSet"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)//0
		_MainTex("Main Texture", 2D) = "white" {}//1
		// Ambient light is applied uniformly to all surfaces on the object.
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)//2
		_RimColor("Rim Color", Color) = (1,1,1,1)//3
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716//4
		// Control how smoothly the rim blends when approaching unlit
		// parts of the surface.
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1//5

		_HsvShift("Hue Shift", Range(0, 360)) = 180 //6
		_HsvSaturation("Saturation", Range(0, 2)) = 1 //7
		_HsvBright("Brightness", Range(0, 2)) = 1 //8

	}

		SubShader
		{
			Pass
			{
				// Setup our pass to use Forward rendering, and only receive
				// data on the main directional light and ambient light.
				Tags
				{
					"LightMode" = "ForwardBase"
					"PassFlags" = "OnlyDirectional"
				}

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#pragma shader_feature HSV_ON
				#pragma shader_feature RIM_ON

			#if FOG_ON
			#pragma multi_compile_fog
			#endif
			// Compile multiple versions of this shader depending on lighting settings.
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			// Files below include macros and functions to assist
			// with lighting and shadows.
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				// Macro found in Autolight.cginc. Declares a vector4
				// into the TEXCOORD2 semantic with varying precision 
				// depending on platform target.
				SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = WorldSpaceViewDir(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				// Defined in Autolight.cginc. Assigns the above shadow coordinate
				// by transforming the vertex from world space to shadow-map space.
				TRANSFER_SHADOW(o)
				return o;
			}

			float4 _Color;
			#if RIM_ON
			float4 _AmbientColor;

			float _Glossiness;

			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;
			#endif

			#if HSV_ON
			half _HsvShift, _HsvSaturation, _HsvBright;
			#endif

			float4 frag(v2f i) : SV_Target
			{
				float4 sample = tex2D(_MainTex, i.uv)*_Color;

				#if RIM_ON
				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(i.viewDir);

				// Calculate illumination from directional light.
				// _WorldSpaceLightPos0 is a vector pointing the OPPOSITE
				// direction of the main directional light.
				float NdotL = dot(_WorldSpaceLightPos0, normal);

				// Samples the shadow map, returning a value in the 0...1 range,
				// where 0 is in the shadow, and 1 is not.
				float shadow = SHADOW_ATTENUATION(i);
				// Partition the intensity into light and dark, smoothly interpolated
				// between the two to avoid a jagged break.
				float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
				// Multiply by the main directional light's intensity and color.
				float4 light = lightIntensity * _LightColor0;

				// Calculate rim lighting.
				float rimDot = 1 - dot(viewDir, normal);
				// We only want rim to appear on the lit side of the surface,
				// so multiply it by NdotL, raised to a power to smoothly blend it.
				float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimColor;

				sample *= (light + _AmbientColor) ;
				sample += rim;
				#endif

				#if HSV_ON
				half3 resultHsv = half3(sample.rgb);
				half cosHsv = _HsvBright * _HsvSaturation * cos(_HsvShift * 3.14159265 / 180);
				half sinHsv = _HsvBright * _HsvSaturation * sin(_HsvShift * 3.14159265 / 180);
				resultHsv.x = (.299 * _HsvBright + .701 * cosHsv + .168 * sinHsv) * sample.x
					+ (.587 * _HsvBright - .587 * cosHsv + .330 * sinHsv) * sample.y
					+ (.114 * _HsvBright - .114 * cosHsv - .497 * sinHsv) * sample.z;
				resultHsv.y = (.299 * _HsvBright - .299 * cosHsv - .328 * sinHsv) * sample.x
					+ (.587 * _HsvBright + .413 * cosHsv + .035 * sinHsv) * sample.y
					+ (.114 * _HsvBright - .114 * cosHsv + .292 * sinHsv) * sample.z;
				resultHsv.z = (.299 * _HsvBright - .3 * cosHsv + 1.25 * sinHsv) * sample.x
					+ (.587 * _HsvBright - .588 * cosHsv - 1.05 * sinHsv) * sample.y
					+ (.114 * _HsvBright + .886 * cosHsv - .203 * sinHsv) * sample.z;
				sample.rgb = resultHsv;
				#endif
				
				
				return sample;
			}
			ENDCG
		}

			// Shadow casting support.
			UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		}
		CustomEditor "MatInspector"
}
