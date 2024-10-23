// Based on original shader code by Zylann
// https://github.com/Zylann/voxel_raytracing/blob/master/voxel_raster.shader
// Uses MagicaVoxel PNG slice exports imported as 3D textures for voxel data
// ©2024 Dan Suwanseree

shader_type spatial;
render_mode shadows_disabled, cull_front, diffuse_toon, specular_toon;

uniform sampler3D voxel_data : filter_nearest;
uniform float voxel_scale : hint_range(0.01, 100.0) = 1.0;
uniform int voxel_longest_diagonal = 1;

varying vec3 v_cam_pos_local;
varying vec3 v_vertex;
varying flat mat3 v_mvp;

void vertex() {
	v_cam_pos_local = ((inverse(MODEL_MATRIX) * INV_VIEW_MATRIX) * vec4(0,0,0,1)).xyz;
	v_vertex = VERTEX;
	v_mvp = mat3(MODELVIEW_MATRIX);
}

// Returns voxel color at specified 3D position
vec4 get_voxel(vec3 pos) {
	// Interesting thing: if you use ivec3(pos * (1.0 / voxel_scale) it's like voxel level scaling
	// (voxels are same size but actualy voxel model is sampled scaled
	return texelFetch(voxel_data, ivec3(pos), 0);
}

vec4 raymarch(vec3 p_rpos, vec3 p_rdir, out vec3 p_normal) {
	vec3 hit_pos = floor(p_rpos);
	vec3 hit_prev_pos = hit_pos;

	vec3 istep = sign(p_rdir);

	vec3 tdelta = 1.0 / abs(p_rdir);
	vec3 tcross = tdelta * mix(p_rpos - floor(p_rpos), ceil(p_rpos) - p_rpos, 0.5 * istep + 0.5);

	vec4 col = vec4(0);

	// Iterations should equal to longest diagonal of the box (sqrt(L^2 + W^2 + H^2))
	// Here multiplied by 1.4 to add some extra iterations to avoid missing hits
	// when viewing from corners
	int iterations = int(float(voxel_longest_diagonal) * 1.4);
	for (int i = 0; i < iterations; ++i) {
		hit_prev_pos = hit_pos;

		// Advance depending on which coordinate is closer to next integer
		// Non-if version is harder to understand but faster (by about 20%)
		float cxy = step(tcross.x, tcross.y);
		float cxz = step(tcross.x, tcross.z);
		float cyz = step(tcross.y, tcross.z);
		vec3 m;
		m.x = cxy * cxz;
		m.y = (1.0 - cxy) * cyz;
		m.z = 1.0 - (m.x + m.y);
		hit_pos += istep * m;
		tcross += tdelta * m;

		vec4 v = get_voxel(hit_pos);
		if (v.r + v.g + v.b != 0.0) {
			col = v;
			break;
		}
	}

	p_normal = hit_prev_pos - hit_pos;

	return col;
}

void fragment() {
	vec3 cam_dir = normalize(v_vertex - v_cam_pos_local);
	vec3 model_pos = vec3(textureSize(voxel_data, 0)) * 0.5;
	vec3 pos = v_vertex * (1.0 / voxel_scale) + model_pos - 0.001 * cam_dir;
	vec3 n;

	vec4 col = raymarch(pos, cam_dir, n);
	if (col.a == 0.0){
		discard;
	}

	ALBEDO = col.rgb;
	NORMAL = v_mvp * n;

	// sRGB
	if (!OUTPUT_IS_SRGB) {
		ALBEDO = mix(pow((ALBEDO + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), ALBEDO * (1.0 / 12.92), lessThan(ALBEDO,vec3(0.04045)));
	}
}