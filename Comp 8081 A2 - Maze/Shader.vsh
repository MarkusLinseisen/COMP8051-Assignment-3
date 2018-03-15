#version 300 es

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texCoordIn;
out vec2 v_texcoord;
out vec3 v_position;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
    v_texcoord = texCoordIn;
    v_position = (modelViewMatrix * position).xyz;
    gl_Position = projectionMatrix * modelViewMatrix * position;
}

