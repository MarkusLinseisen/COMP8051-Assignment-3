#version 300 es

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texCoordIn;
layout(location = 2) in vec3 normal;
out vec2 v_texcoord;
out vec3 v_position;
out vec3 v_normal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
    v_texcoord = texCoordIn;
    v_position = (modelViewMatrix * position).xyz;
    v_normal = normalize(mat3(modelViewMatrix) * normal);
    gl_Position = projectionMatrix * modelViewMatrix * position;
}
