// Noise animation - Lava
// by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/lslXRS
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

Shader "Unity-Noises/LavaNoiseWithoutTexture/Update"
{
	Properties
	{
		_NoiseScale("Noise Scale", Float) = 0.01
		_NoiseSpeed("Noise Speed", Float) = 0.01
		_Scale("Scale", Float) = 3
		_Speed("Speed", Float) = 0.1
		_Octaves("Octaves", Int) = 6
		_FlowSpeeds("Primary/Secondary Flow Speeds", Vector) = (0.6, 0.6, 1.9, 1.9)
		_DisplacementFieldScale("Displacement Field Scale", Float) = 1
		_DisplacementFieldRotationSpeed("Displacement Field Rotation Speed", Float) = 6
		_DisplacementStrength("Displacement Strength", Float) = 0.5
		_AdvectionFactor("Advection Factor", Range(0,1)) = .77
		_IsTimeControlled("Is time controlled ? (1=yes)", Range(0,1)) = 0
		_ControlledTime("Controlled Time", Float) = 0
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

		float _NoiseScale;
		float _NoiseSpeed;

		float _Scale;
		float _Speed;
		uint _Octaves;

		float _DisplacementFieldScale;
		float _DisplacementFieldRotationSpeed;
		float _DisplacementStrength;
		float _AdvectionFactor;
		float4 _FlowSpeeds;

		float _IsTimeControlled;
		float _ControlledTime;

		float3 mod289(float3 x)
		{
			return x - floor(x / 289.0) * 289.0;
		}

		float4 mod289(float4 x)
		{
			return x - floor(x / 289.0) * 289.0;
		}

		float4 permute(float4 x)
		{
			return mod289((x * 34.0 + 1.0) * x);
		}

		float4 taylorInvSqrt(float4 r)
		{
			return 1.79284291400159 - r * 0.85373472095314;
		}

		//Simplex noise
		float SimplexNoise(float3 v)
		{
			const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);

			// First corner
			float3 i = floor(v + dot(v, C.yyy));
			float3 x0 = v - i + dot(i, C.xxx);

			// Other corners
			float3 g = step(x0.yzx, x0.xyz);
			float3 l = 1.0 - g;
			float3 i1 = min(g.xyz, l.zxy);
			float3 i2 = max(g.xyz, l.zxy);

			// x1 = x0 - i1  + 1.0 * C.xxx;
			// x2 = x0 - i2  + 2.0 * C.xxx;
			// x3 = x0 - 1.0 + 3.0 * C.xxx;
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy;
			float3 x3 = x0 - 0.5;

			// Permutations
			i = mod289(i); // Avoid truncation effects in permutation
			float4 p =
				permute(permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0))
					+ i.y + float4(0.0, i1.y, i2.y, 1.0))
					+ i.x + float4(0.0, i1.x, i2.x, 1.0));

			// Gradients: 7x7 points over a square, mapped onto an octahedron.
			// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
			float4 j = p - 49.0 * floor(p / 49.0);  // mod(p,7*7)

			float4 x_ = floor(j / 7.0);
			float4 y_ = floor(j - 7.0 * x_);  // mod(j,N)

			float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
			float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

			float4 h = 1.0 - abs(x) - abs(y);

			float4 b0 = float4(x.xy, y.xy);
			float4 b1 = float4(x.zw, y.zw);

			//float4 s0 = float4(lessThan(b0, 0.0)) * 2.0 - 1.0;
			//float4 s1 = float4(lessThan(b1, 0.0)) * 2.0 - 1.0;
			float4 s0 = floor(b0) * 2.0 + 1.0;
			float4 s1 = floor(b1) * 2.0 + 1.0;
			float4 sh = -step(h, 0.0);

			float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
			float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

			float3 g0 = float3(a0.xy, h.x);
			float3 g1 = float3(a0.zw, h.y);
			float3 g2 = float3(a1.xy, h.z);
			float3 g3 = float3(a1.zw, h.w);

			// Normalise gradients
			float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
			g0 *= norm.x;
			g1 *= norm.y;
			g2 *= norm.z;
			g3 *= norm.w;

			// Mix final noise value
			float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
			m = m * m;
			m = m * m;

			float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
			return 42.0 * dot(m, px);
		}

		float noise(float2 x)
		{
			return SimplexNoise(float3(x * _NoiseScale, _ControlledTime * _NoiseSpeed));
		}

		float2x2 makem2(float theta)
		{
			float c = cos(theta);
			float s = sin(theta);
			return float2x2(c, -s, s, c);
		}

		float2 gradn(float2 p)
		{
			float ep = .09;
			float gradx = noise(float2(p.x + ep, p.y)) - noise(float2(p.x - ep, p.y));
			float grady = noise(float2(p.x, p.y + ep)) - noise(float2(p.x, p.y - ep));
			return float2(gradx, grady);
		}

		float flow(float2 p, float time)
		{
			float z = 2.;
			float rz = 0.;
			float2 bp = p;
			for (int i = 1; i <= _Octaves; i++)
			{
				//primary flow speed
				p += time * _FlowSpeeds.xy;

				//secondary flow speed (speed of the perceived flow)
				bp += time * _FlowSpeeds.zw;

				//displacement field (try changing time multiplier)
				float2 gr = gradn(i * p * .34 + time * _DisplacementFieldScale);

				//rotation of the displacement field
				gr = mul(makem2(time * _DisplacementFieldRotationSpeed - (0.05 * p.x + 0.03 * p.y) * 40.), gr);

				//displace the system
				p += gr * _DisplacementStrength;

				//add noise octave
				rz += (sin(noise(p) * 7.) * 0.5 + 0.5) / z;

				//blend factor (blending displaced system with base system)
				//you could call this advection factor (.5 being low, .95 being high)
				p = lerp(bp, p, _AdvectionFactor);

				//intensity scaling
				z *= 1.4;
				//octave scaling
				p *= 2.;
				bp *= 1.9;
			}
			return rz;
		}

		float4 frag(v2f_customrendertexture i) : SV_Target
		{
			float2 uv = i.globalTexcoord;

			//Center uv
			uv -= 0.5f;

			//Scale uv to match texture ratio
			uv.x *= (float)_CustomRenderTextureWidth / _CustomRenderTextureHeight;

			//Scale
			uv *= _Scale;

			return float4(1, 1, 1, 1) * flow(uv, _IsTimeControlled == 1.0f ? _ControlledTime * _Speed : _Time.y * _Speed);
		}

			ENDCG

			SubShader
		{
			Cull Off ZWrite Off ZTest Always
				Pass
			{
				Name "Update"
				CGPROGRAM
				#pragma vertex CustomRenderTextureVertexShader
				#pragma fragment frag
				ENDCG
			}
		}
}
