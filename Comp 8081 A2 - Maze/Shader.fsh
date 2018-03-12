#version 300 es

precision highp float;
in vec2 v_texcoord;
in vec3 v_position;
out vec4 o_fragColor;

uniform sampler2D texSampler;

uniform mat4 modelViewMatrix;
uniform bool spotlight;
uniform float spotlightCutoff;
uniform vec4 spotlightColor;
uniform vec4 skyColor;
uniform bool fog;
uniform float fogEnd;

void main() {
    vec4 linearColor = skyColor;
    
    if (spotlight) {
        float spotlightValue = dot(normalize(v_position), vec3(0.0, 0.0, -1.0));
        if (spotlightValue > spotlightCutoff) {
            linearColor += spotlightColor;
        }
    }
    
    linearColor *= texture(texSampler, v_texcoord);
    
    if (fog) {
        float fogMix = min(1.0, length(v_position) / fogEnd);
        linearColor = mix(linearColor, skyColor, fogMix);
    }
    
    o_fragColor = linearColor;
}
