Shader "Unity-Noises/SimplexNoise3D/Update"
{
	Properties
	{
		_Scale("Scale", Range(0,10)) = 5
		_Offset("Offset", Range(-3, 3)) = 0
		_Speed("Speed", Range(-5,5)) = 0.3
		_Octave("OctaveNumber", Range(1,6)) = 6
		_OctaveScale("OctaveScaleIncrease", Range(0,10)) = 2
		_Attenuation("OctaveAttenuation", Range(0,1)) = 0.5
	}

	CGINCLUDE

	#include "UnityCustomRenderTexture.cginc"
	#include "../../../Includes/SimplexNoise3D.hlsl"

	float _Octave;
	float _OctaveScale;
	float _Scale;
	float _Offset;
	float _Attenuation;
	float _Speed;

    half4 frag(v2f_customrendertexture i) : SV_Target
    {
        float2 uv = i.globalTexcoord;

		float4 output = _Offset;
		/*
        float scale = _Scale;
        float weight = 1.0f;
		float harmonicWeight = 1.0f - _Attenuation;

		uint OctaveNumber = uint(_Octave);

        for (uint i = 0; i < OctaveNumber; i++)
        {
            float3 coord = float3(uv * scale, _Time.y * _Speed);

			output += snoise(coord) * weight;

            scale *= _OctaveScale;
            weight *= harmonicWeight;
        }
		*/

		output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation);

		return output;

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
