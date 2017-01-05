#define hud_depth IniParams[0].x
#define hud_3d_convergence_override IniParams[0].y
#define hud_3d_convergence_override_mouse_showing IniParams[0].z
#define hud_3d_threshold IniParams[0].w
#define lens_grit_depth IniParams[2].y
#define cursor_showing IniParams[1].w

void to_screen_depth(inout float4 pos)
{
	float4 s = StereoParams.Load(0);

	pos.x -= s.x * (pos.w - s.y);
}

void to_hud_depth(inout float4 pos)
{
	float4 s = StereoParams.Load(0);

	if (cursor_showing)
		return;

	pos.x += s.x * hud_depth * pos.w;
}

float2 to_lens_grit_depth(float2 texcoord)
{
	float4 s = StereoParams.Load(0);

	// Adjust depth of dirty lens effect, stretching to avoid the effect clipping
	// at edge of screen:
	float multiplier = s.x * lens_grit_depth;
	if (s.z == 1) /* left eye */
		texcoord.x = (1 + multiplier) * (texcoord.x - 1) + 1;
	else /* right eye */
		texcoord.x *= 1 - multiplier;

	return texcoord;
}

void screen_to_infinity(inout float4 pos)
{
	float4 s = StereoParams.Load(0);

	pos.x += s.x * pos.w;
}

void depth_to_infinity(inout float4 pos)
{
	float4 s = StereoParams.Load(0);

	pos.x += s.x * s.y;
}

void convergence_override(inout float4 pos, float convergence_override)
{
	float4 s = StereoParams.Load(0);

	pos.x += s.x * (s.y - convergence_override);
}

void biased_stereo_correct_with_convergence_override(inout float4 pos, float depth_bias, float convergence_override)
{
	float4 s = StereoParams.Load(0);

	pos.x += s.x * (pos.w + depth_bias - convergence_override) * pos.w / (pos.w + depth_bias);
}

void override_hud_convergence(inout float4 pos)
{
	float4 s = StereoParams.Load(0);
	float world_hud_depth;
	float depth_bias;

	if (cursor_showing) {
		// Mouse cursor showing - override the convergence to a
		// specific value to make the menu easier to use:
		convergence_override(pos, hud_3d_convergence_override_mouse_showing);
		return;
	}

	if (hud_depth == 1) {
		depth_to_infinity(pos);
		return;
	}

	world_hud_depth = -hud_3d_convergence_override / (hud_depth - 1);
	depth_bias = world_hud_depth - hud_3d_convergence_override;

	to_screen_depth(pos);
	biased_stereo_correct_with_convergence_override(pos, depth_bias, hud_3d_convergence_override);
}

void handle_3d_hud(inout float4 pos)
{
	if (pos.w > hud_3d_threshold) // Likely already at correct depth, don't adjust
		return;

	override_hud_convergence(pos);
}
