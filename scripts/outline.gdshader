shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shine_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float shine_speed : hint_range(0.0, 10.0) = 1.0;
uniform float edge_thickness : hint_range(0.0, 2.0) = 1.0;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec3 base_color = vec3(0.5, 0.5, 0.5);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb * base_color;
    ROUGHNESS = roughness;
    METALLIC = metallic;

    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    fresnel *= edge_thickness;

    float pulse = sin(TIME * shine_speed) * 0.5 + 0.5;

    vec3 shine = shine_color.rgb * fresnel * pulse * shine_intensity;
    EMISSION = shine;
}
