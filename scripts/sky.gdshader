shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.02, 0.05, 0.1);
uniform vec3 horizon_color : source_color = vec3(0.1, 0.1, 0.15);
uniform float lightning_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(0.8, 0.9, 1.0);

void sky() {
    float horizon_mask = abs(EYEDIR.y);
    vec3 final_sky = mix(horizon_color, sky_color, horizon_mask);
    
    // Add lightning flash influence
    final_sky = mix(final_sky, flash_color, lightning_flash);
    
    COLOR = final_sky;
}