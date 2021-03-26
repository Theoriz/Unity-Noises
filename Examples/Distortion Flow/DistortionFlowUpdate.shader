/* Taken from https://catlikecoding.com/unity/tutorials/flow/texture-distortion/ */

Shader "Unity-Noises/DistortionFlow/Update"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _FlowMap("Flow (RG, A noise)", 2D) = "black" {}
		_UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling("Tiling", Float) = 1
		_Speed("Speed", Float) = 1
		_FlowStrength("Flow Strength", Float) = 1
		_FlowOffset("Flow Offset", Float) = 0
		_IsTimeControlled("Is time controlled ? (1=yes)", Range(0,1)) = 0
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"
#include "../../Includes/Flow.cginc"

			sampler2D _MainTex, _FlowMap;
		float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset;

		fixed4 _Color;
		float _IsTimeControlled;
		float _ControlledTime;

    half4 frag(v2f_customrendertexture i) : SV_Target
    {
		float2 uv = i.globalTexcoord;
		float3 flow = tex2D(_FlowMap, uv).rgb;
		flow.xy = flow.xy * 2 - 1;
		flow *= _FlowStrength;
		float noise = tex2D(_FlowMap, uv).a;
		float time = _IsTimeControlled == 1.0f ? _ControlledTime : _Time.y;
		time = time * _Speed + noise;
		float2 jump = float2(_UJump, _VJump);

		float3 uvwA = FlowUVW(
			uv, flow.xy, jump,
			_FlowOffset, _Tiling, time, false
		);
		float3 uvwB = FlowUVW(
			uv, flow.xy, jump,
			_FlowOffset, _Tiling, time, true
		);

		fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
		fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

		return (texA + texB) * _Color;

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
