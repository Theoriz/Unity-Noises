Shader "Unity-Noises/IFS2D/Update"
{
	Properties
	{
		_ScaleX("Scale X", Float) = 1
		_ScaleY("Scale Y", Float) = 1
		_AA("AntiAliasing", Int) = 2
		_MAXSTEPS("RayMarching Max Steps", int) = 50
		_HITTHRESHOLD("RayMarching Hit Threshold", Float) = 0.009
		_FAR("RayMarching Far Distance", Float) = 250.
		_NIFS("IFS Iterations", int) = 6
		_IFSScale("IFS Scale", Float) = 2.3
		_IFSTranslate("IFS Translate", Float) = 1.5
		_IFSRadius("IFS Radius", Float) = 0.5
		_TimeSpeed("Time Speed", Float) = 1
		_IsTimeControlled("Is time controlled ? (1=yes)", Range(0,1)) = 0
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

		/* Taken from https://www.shadertoy.com/view/tsBSWD */

	float _ScaleX;
	float _ScaleY;
	int _AA;
	int _MAXSTEPS;
	float _HITTHRESHOLD;
	float _FAR;
	int _NIFS;
	float _IFSScale;
	float _IFSTranslate;
	float _IFSRadius;
	float _IsTimeControlled;
	float _TimeSpeed;
	float _ControlledTime;

	float2x2 rot(float angle)
	{
		float c = cos(angle);
		float s = sin(angle);
		return float2x2(c, -s,
			s, c);
	}

	float4 sd2d(float2 p, float o, float time)
	{
		float s = 0.5;
		p *= s;
		//float _RADIUS =1.;//+sin(2.0*iTime));
		int i;
		float3 col;
		//p = p*rot(-0.4*time);// twist

		for (i = 0; i<_NIFS; i++)
		{
			if (p.x<0.)
			{//p.x = -p.x;
				col.r++;
			}
			p = mul(rot(0.9*sin(time)), p);
			if (p.y<0.) {
				p.y = -p.y;
				col.g++;
			}
			if (p.x - p.y<0.) { p.xy = p.yx;col.b++; }
			p = p * _IFSScale - _IFSTranslate;
			//p = p*rot(0.3*(iTime));
		}

		float d = 0.425*(length(p) - _IFSRadius) * pow(_IFSScale, float(-i)) / s;
		col /= float(_NIFS);
		//float3 oc = mix(float3(0.7,col.g,0.2),float3(0.2,col.r,0.7), col.b);
		float intensity = (col.r + col.g + col.b) / 3.0;
		float3 oc = float3(intensity, intensity, intensity);

		return float4(oc, d);
	}

	float4 map(float3 p, float time)
	{
		return sd2d(p.xz, p.y, time);
	}

	float shadow(float3 ro, float3 rd, float time)
	{
		float h = 0.;
		float k = 3.5;//shadowSmooth
		float res = 1.;
		float t = 0.2; //bias
		for (int i = 0; t < 15.; i++) // t < shadowMaxDist
		{
			h = map(ro + rd * t, time).w;
			res = min(res, k*h / t);
			if (h < _HITTHRESHOLD)
			{
				break;
			}
			t = t + h;
		}
		return clamp(res + 0.05, 0., 1.);
	}

    half4 frag(v2f_customrendertexture i) : SV_Target
    {
        float2 uv = i.globalTexcoord;
        
		float time = _IsTimeControlled == 1.0f ? _ControlledTime : _Time.y;
		time *= _TimeSpeed;

		//camera
		float height = -0.4;
		float rot = time * 0.1;
		float dist = 9. + 1.*sin(0.5*time);
		float3 ro = dist * float3(cos(rot), height, sin(rot));
		float3 lookAt = float3(0., 0., 0.);
		float3 fw = normalize(lookAt - ro);
		//tilting camera for a "weirder" feel when rotating around Y axis
		float3 right = normalize(cross(float3(0., 1., 1.), fw));
		float3 up = normalize(cross(fw, right));
		right = normalize(cross(up, fw));

		//light
		rot += sin(time)*0.2;
		float3 lightPos = dist * float3(cos(rot), height, sin(rot));

		//raymarch
		float3 pos, closest;
		float t;
		float smallest;
		int j;
		float3 sdfCol;
		float3 col;

		for (int x = 0; x<_AA;x++)
			for (int y = 0; y<_AA;y++)
			{
				t = 0.; smallest = 500.;
				float2 o = float2(float(x), float(y)) / float(_AA) - 0.5;
				uv += o;
				//uv -= 0.5;
				uv.x *= _ScaleX;
				uv.y *= _ScaleY;
				float3 rd = normalize(fw *0.5 + right * uv.x + up * uv.y);

				for (j = 0; j<_MAXSTEPS; j++)
				{
					pos = ro + rd * t;
					float4 mr = map(pos, time);
					float d = mr.w;
					if (d < smallest) smallest = d; closest = pos; sdfCol = mr.rgb;
					if (abs(d)<_HITTHRESHOLD || t> _FAR) { break; }
					t += d;
				}
				pos = closest;
				float3 c;
				if (t<_FAR)
				{
					c = sdfCol;
					float3 toLight = normalize(lightPos-pos);
					float s = shadow(pos,toLight, time);
					c*=s; 
					c = lerp(c, 1.5*c,1.-s);
				}
				else
				{
					c = float3(0, 0, 0);
				}
				col += c;
			}
		col /= float(_AA*_AA);

		return float4(col, t);

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
