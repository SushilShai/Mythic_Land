shader_type canvas_item;

uniform sampler2D red_overlay_tex: repeat_enable, filter_nearest;   // for red
uniform sampler2D sand_overlay_tex: repeat_enable, filter_nearest;  // for sand
uniform float scale = 0.006944444;
uniform float tolerance = 0.05;
varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 red_overlay = texture(red_overlay_tex, world_position * scale);
    vec4 sand_overlay = texture(sand_overlay_tex, world_position * scale);

    // Target colors
    vec3 red_target = vec3(1.0, 0.0, 0.0);
    vec3 sand_target = vec3(0.243, 1.0, 0.0); // #3eff00

    // Detect pixels close to targets
    float red_mask = step(distance(COLOR.rgb, red_target), tolerance);
    float sand_mask = step(distance(COLOR.rgb, sand_target), tolerance);

    vec4 final_color = COLOR;

    // Apply red overlay only where red_mask is true
    final_color = mix(final_color, red_overlay, red_mask);

    // Apply sand overlay only where sand_mask is true
    final_color = mix(final_color, sand_overlay, sand_mask);

    COLOR = final_color;
}
