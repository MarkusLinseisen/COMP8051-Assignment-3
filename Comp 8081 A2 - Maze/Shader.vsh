#version 300 es

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec2 texCoordIn;
out vec4 v_color;
out vec3 v_normal;
out vec2 v_texcoord;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;
uniform bool passThrough;
uniform bool shadeInFrag;

void main() {
    v_color = color;
    v_normal = normal;
    v_texcoord = texCoordIn;
    
    gl_Position = modelViewProjectionMatrix * position;
}

