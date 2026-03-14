shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform vec3 emission_color : source_color;
uniform float emission_energy = 5.0;

void fragment() {
    ALBEDO = albedo.rgb;
    // Emission needs high values for glow
    EMISSION = emission_color * emission_energy;
}
