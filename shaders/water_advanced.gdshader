shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

// Water colors
uniform vec4 shallow_color : source_color = vec4(0.3, 0.5, 0.7, 0.8);
uniform vec4 deep_color : source_color = vec4(0.1, 0.2, 0.4, 0.95);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Wave parameters
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.2;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wave_turbulence : hint_range(0.0, 1.0) = 0.3;

// Surface properties
uniform float transparency : hint_range(0.0, 1.0) = 0.85;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.2;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float refraction_amount : hint_range(0.0, 0.5) = 0.1;

// Texture maps (optional)
uniform sampler2D normal_map : hint_normal;
uniform sampler2D foam_texture;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

varying float wave_height;
varying vec3 world_pos;
varying vec2 wave_uv;

// Improved noise function for more organic waves
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float time = TIME * wave_speed;
    
    // Create multiple wave layers for realism
    wave_height = 0.0;
    
    // Primary wave
    wave_height += sin(world_pos.x * wave_frequency + time) * wave_amplitude;
    wave_height += sin(world_pos.z * wave_frequency * 0.8 - time * 1.2) * wave_amplitude * 0.7;
    
    // Secondary cross wave
    wave_height += sin((world_pos.x + world_pos.z) * wave_frequency * 0.5 + time * 0.8) * wave_amplitude * 0.5;
    
    // Add turbulence using noise
    vec2 noise_coord = world_pos.xz * 0.1 + vec2(time * 0.1);
    float turbulence = noise(noise_coord) * wave_turbulence;
    wave_height += turbulence * wave_amplitude;
    
    // Apply wave to vertex
    VERTEX.y += wave_height;
    
    // Calculate UV for wave-based effects
    wave_uv = world_pos.xz * 0.05 + vec2(time * 0.02);
    
    // Create slight horizontal displacement for more realistic waves
    VERTEX.x += sin(world_pos.z * wave_frequency * 2.0 + time * 2.0) * wave_amplitude * 0.1;
    VERTEX.z += sin(world_pos.x * wave_frequency * 2.0 - time * 2.0) * wave_amplitude * 0.1;
}

void fragment() {
    // Calculate wave-based color mixing
    float wave_factor = clamp((wave_height + wave_amplitude) / (2.0 * wave_amplitude), 0.0, 1.0);
    vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, wave_factor);
    
    // Add foam on wave peaks
    float foam_factor = 0.0;
    if (wave_factor > foam_threshold) {
        foam_factor = (wave_factor - foam_threshold) / (1.0 - foam_threshold);
        
        // Sample foam texture if available
        if (textureSize(foam_texture, 0).x > 1) {
            vec2 foam_uv = wave_uv * 3.0;
            foam_factor *= texture(foam_texture, foam_uv).r;
        }
        
        water_color = mix(water_color, foam_color.rgb, foam_factor * 0.6);
    }
    
    // Apply normal mapping for surface detail
    vec3 normal = NORMAL;
    if (textureSize(normal_map, 0).x > 1) {
        vec3 normal_tex = texture(normal_map, wave_uv).xyz * 2.0 - 1.0;
        normal_tex.xy *= normal_strength;
        normal = normalize(mix(NORMAL, normal_tex, 0.5));
    }
    
    // Calculate fresnel effect for realistic water reflection
    float fresnel = pow(1.0 - dot(normalize(VIEW), normal), 2.0);
    
    // Refraction effect
    vec2 refraction_offset = normal.xy * refraction_amount;
    
    // Final color composition
    ALBEDO = water_color;
    ALPHA = mix(transparency, 1.0, fresnel * 0.3 + foam_factor * 0.5);
    ROUGHNESS = mix(roughness, 0.5, foam_factor);
    METALLIC = metallic * (1.0 - foam_factor);
    NORMAL = normal;
    
    // Add slight emission for foam
    if (foam_factor > 0.1) {
        EMISSION = foam_color.rgb * foam_factor * 0.1;
    }
}