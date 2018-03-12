#version 300 es

precision highp float;
in vec4 v_color;
in vec3 v_normal;
in vec2 v_texcoord;
in vec3 v_position;
out vec4 o_fragColor;

uniform sampler2D texSampler;

uniform mat4 modelViewMatrix;
uniform bool spotlight;

void main() {
    // spotlight points into the screen
    const vec3 lightDirection = vec3(0.0, 0.0, -1.0);
    // spotlight has a 10° FOV. 0.9962 = cos(10°/2)
    const float spotlightCutoff = 0.9962;
    const float attenuationCoef = 0.25;
    const vec4 fogColor = vec4(0.5, 0.5, 0.5, 1.0);
    const float fogEnd = 20.0;
    
    vec3 eyeNormal = normalize(mat3(modelViewMatrix) * v_normal);
    float nDotVP = max(0.0, dot(eyeNormal, -lightDirection));
    
    if (spotlight) {
        float spotlightValue = dot(normalize(v_position), lightDirection);
        if (spotlightValue < spotlightCutoff) {
            nDotVP *= 0.25;
        }
    }
    
    float attenuation = 1.0 / pow(length(v_position * attenuationCoef), 2.0);
    vec4 linearColor = v_color * nDotVP * attenuation * texture(texSampler, v_texcoord);
    float fogMix = min(1.0, length(v_position) / fogEnd);
    o_fragColor = mix(linearColor, fogColor, fogMix);
}
