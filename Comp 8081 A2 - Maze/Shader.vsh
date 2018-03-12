#version 300 es

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec2 texCoordIn;
out vec4 v_color;
out vec3 v_normal;
out vec2 v_texcoord;
out vec3 v_position;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
    v_color = color;
    v_normal = normal;
    v_texcoord = texCoordIn;
    v_position = (modelViewMatrix * position).xyz;
    
    gl_Position = projectionMatrix * modelViewMatrix * position;
}

