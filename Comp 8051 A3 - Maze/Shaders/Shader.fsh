#version 300 es

precision highp float;
in vec2 v_texcoord;
in vec3 v_position;
in vec3 v_normal;
out vec4 o_fragColor;

uniform sampler2D texSampler;
uniform vec4 ambientColor;
uniform bool spotlight;
uniform float spotlightCutoff;
uniform vec4 spotlightColor;
uniform bool fog;
uniform vec4 fogColor;
uniform float fogEnd;
uniform float fogDensity;
uniform bool fogUseExp;

void main() {
    vec3 normal = normalize(v_normal);
    float halfLambert = dot(normal, vec3(0,1,0)) * 0.5 + 0.5;
    vec4 linearColor = halfLambert * ambientColor;
    
    if (spotlight) {
        float spotlightValue = dot(normalize(v_position), vec3(0.0, 0.0, -1.0));
        if (spotlightValue > spotlightCutoff) {
            halfLambert = dot(normal, normalize(-v_position)) * 0.5 + 0.5;
            linearColor += spotlightColor * halfLambert * sqrt((spotlightValue - spotlightCutoff) / (1.0 - spotlightCutoff));
        }
    }
    
    linearColor *= texture(texSampler, v_texcoord);
    
    if (fog) {
        float fogMix;
        if (fogUseExp) {
            fogMix = exp(-length(v_position) * fogDensity);
        } else {
            fogMix = max(0.0, 1.0 - length(v_position) / fogEnd);
        }
        linearColor = mix(fogColor, linearColor, fogMix);
    }
    
    o_fragColor = linearColor;
}
