// Source: https://kidscancode.org/godot_recipes/shaders/blur/

shader_type canvas_item;

// FIXME: blur_amount and modulate have to be hardcoded; the shader parameters
// are not being used on exported projects from the editor
// So far this hasn't been replicated on vanilla Godot, but it's likely
// an engine bug. Investigate later
uniform float blur_amount : hint_range(0, 5);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 modulate : source_color;

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount) * modulate;
}