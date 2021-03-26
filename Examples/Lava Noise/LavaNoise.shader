// Noise animation - Lava
// by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/lslXRS
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

Shader "Unity-Noises/LavaNoise/Update"
{
	Properties
	{
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_NoiseTexScale("Noise Texture Scale", Float) = 0.01
		_Scale("Scale", Float) = 3
		_Speed("Speed", Float) = 0.1
		_Octaves("Octaves", Int) = 6
		_FlowSpeeds("Primary/Secondary Flow Speeds", Vector) = (0.6, 0.6, 1.9, 1.9)
		_DisplacementFieldScale("Displacement Field Scale", Float) = 1
		_DisplacementFieldRotationSpeed("Displacement Field Rotation Speed", Float) = 6
		_DisplacementStrength("Displacement Strength", Float) = 0.5
		_AdvectionFactor("Advection Factor", Range(0,1)) = .77
		_IsTimeControlled("Is time controlled ? (1=yes)", Range(0,1)) = 0
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

		sampler2D _NoiseTex;
		float _NoiseTexScale;

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

		float noise(float2 x) 
		{ 
			return tex2D(_NoiseTex, x * _NoiseTexScale).x; 
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
