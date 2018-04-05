#version 300 es

precision mediump float;

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
    const vec3 ambientDirection = vec3(0.0, -1.0, 0.0);
    const vec3 spotlightDirection = vec3(0.0, 0.0, -1.0);
    
    float position_length = length(v_position);
    vec3 position = v_position / position_length;
    vec3 normal = normalize(v_normal);

    float diffuseCoefficient = dot(normal, -ambientDirection) * 0.5 + 0.5;
    vec4 diffuse = ambientColor * diffuseCoefficient;
    float rimCoefficient = dot(normal, position) * 0.5 + 0.5;
    vec4 rim = rimCoefficient * ambientColor;

    if (spotlight) {
        float spotlightValue = dot(position, spotlightDirection);
        if (spotlightValue > spotlightCutoff) {
            diffuseCoefficient = dot(normal, -position) * 0.5 + 0.5;
            diffuse += spotlightColor * diffuseCoefficient * sqrt((spotlightValue - spotlightCutoff) / (1.0 - spotlightCutoff));
        }
    }
    
    diffuse *= texture(texSampler, v_texcoord);
    vec4 linearColor = diffuse + rim;
    
    if (fog) {
        float fogMix;
        if (fogUseExp) {
            fogMix = exp(-position_length * fogDensity);
        } else {
            fogMix = max(0.0, 1.0 - position_length / fogEnd);
        }
        linearColor = mix(fogColor, linearColor, fogMix);
    }
    
    o_fragColor = linearColor;
}
