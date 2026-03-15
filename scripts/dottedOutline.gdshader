shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float density = 10.0;
uniform float dot_size = 0.5;
uniform float speed = 1.0;

varying vec3 world_pos;

void vertex() {
    world_pos = VERTEX;
}

void fragment() {
    float position = mod(world_pos.z * density + TIME * speed, 1.0);

    if (position > dot_size) {
        discard;
    }
    
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
