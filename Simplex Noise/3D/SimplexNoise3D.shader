Shader "Unity-Noises/SimplexNoise3D"
{
	Properties
	{
		_Scale("Scale", Range(0,10)) = 1
		_Offset("Offset", Range(-1, 1)) = 0.5
		_Speed("Speed", Range(-5,5)) = 1
		_Fractal("FractalNumber", Range(1,6)) = 1
		_FractalScale("FractalScaleIncrease", Range(0,10)) = 2
		_Attenuation("FractalAttenuation", Range(0,1)) = 0.5
	}

	CGINCLUDE

	#include "UnityCustomRenderTexture.cginc"
	#include "SimplexNoise3D.hlsl"

	float _Fractal;
	float _FractalScale;
	float _Scale;
	float _Offset;
	float _Attenuation;
	float _Speed;

    half4 frag(v2f_customrendertexture i) : SV_Target
    {
        const float epsilon = 0.0001;

        float2 uv = i.globalTexcoord;

        float3 output = _Offset;
        float scale = _Scale;
        float weight = 1.0f;
		float harmonicWeight = 1.0f - _Attenuation;

		uint fractalNumber = uint(_Fractal);

        for (uint i = 0; i < fractalNumber; i++)
        {
            float3 coord = float3(uv * scale, _Time.y * _Speed);

			output += snoise_grad(coord) * weight;

            scale *= _FractalScale;
            weight *= harmonicWeight;
        }

        return float4(output.xyz, 1);

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
