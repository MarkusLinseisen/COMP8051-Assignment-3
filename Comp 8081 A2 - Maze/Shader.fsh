#version 300 es

precision highp float;
in vec2 v_texcoord;
in vec3 v_position;
out vec4 o_fragColor;

uniform sampler2D texSampler;
uniform bool spotlight;
uniform float spotlightCutoff;
uniform vec4 spotlightColor;
uniform vec4 skyColor;
uniform bool fog;
uniform float fogEnd;
uniform float fogDensity;
uniform bool fogUseExp;

void main() {
    vec4 linearColor = skyColor;
    
    if (spotlight) {
        float spotlightValue = dot(normalize(v_position), vec3(0.0, 0.0, -1.0));
        if (spotlightValue > spotlightCutoff) {
            linearColor += spotlightColor * sqrt((spotlightValue - spotlightCutoff) / (1.0 - spotlightCutoff));
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
        linearColor = mix(skyColor, linearColor, fogMix);
    }
    
    o_fragColor = linearColor;
}
