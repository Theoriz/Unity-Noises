#if !defined(FLOW_INCLUDED)
#define FLOW_INCLUDED

float3 FlowUVW (
	float2 uv, float2 flowVector, float2 jump,
	float flowOffset, float tiling, float time, bool flowB
) {
	float phaseOffset = flowB ? 0.5 : 0;
	float progress = frac(time + phaseOffset);
	float3 uvw;
	uvw.xy = uv - flowVector * (progress + flowOffset);
	uvw.xy *= tiling;
	uvw.xy += phaseOffset;
	uvw.xy += (time - progress) * jump;
	uvw.z = 1 - abs(1 - 2 * progress);
	return uvw;
}

#endif