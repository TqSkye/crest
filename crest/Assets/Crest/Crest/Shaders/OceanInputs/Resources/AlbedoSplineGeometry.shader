﻿// Crest Ocean System

// This file is subject to the MIT License as seen in the root of this folder structure (LICENSE)

// Generates waves from geometry that is rendered into the water simulation from a top down camera. Expects
// following data on verts:
//   - POSITION: Vert positions as normal.
//   - TEXCOORD0: Axis - direction for waves to travel. "Forward vector" for waves.
//   - TEXCOORD1: X - 0 at start of waves, 1 at end of waves
//
//  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ uv1.x = 0             |
//  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  |                    |  uv0 - wave direction vector
//  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  |                   \|/
//  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ uv1.x = 1
//  ------------------- shoreline --------------------
//

Shader "Hidden/Crest/Inputs/Albedo/Spline Geometry"
{
    SubShader
    {
        // Additive blend everywhere
        Blend One One
        ZWrite Off
        ZTest Always
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            // #pragma enable_d3d11_debug_symbols

            #include "UnityCG.cginc"

            #include "../../OceanGlobals.hlsl"
            #include "../../OceanInputsDriven.hlsl"
            #include "../../OceanHelpersNew.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 axis : TEXCOORD0;
                float invNormDistToShoreline : TEXCOORD1;
                float alpha : TEXCOORD2;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD1;
                float invNormDistToShoreline : TEXCOORD4;
                float alpha : TEXCOORD5;
            };

            CBUFFER_START(GerstnerPerMaterial)
            half _FeatherWaveStart;
            CBUFFER_END

            CBUFFER_START(CrestPerOceanInput)
            float _Weight;
            CBUFFER_END

			sampler2D _albedo;

            Varyings Vert(Attributes v)
            {
                Varyings o;

                const float3 positionOS = v.positionOS;
                o.positionCS = UnityObjectToClipPos(positionOS);
                const float3 worldPos = mul( unity_ObjectToWorld, float4(positionOS, 1.0) ).xyz;

                o.invNormDistToShoreline = v.invNormDistToShoreline;

				o.uv.x = dot(float3(v.axis.x, 0, v.axis.y), worldPos) / 2.0;
				o.uv.y = 2.0 * v.invNormDistToShoreline;

                o.alpha = v.alpha;

                return o;
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float alpha = _Weight * input.alpha;

                // Feather at front/back
                if( input.invNormDistToShoreline > 0.5 ) input.invNormDistToShoreline = 1.0 - input.invNormDistToShoreline;
                alpha *= min( input.invNormDistToShoreline / _FeatherWaveStart, 1.0 );

				float4 sample = tex2D(_albedo, input.uv);

                return float4(sample.xyz, alpha * sample.w);
            }
            ENDCG
        }
    }
}
