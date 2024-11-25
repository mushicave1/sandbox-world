#version 330 core

layout (location = 0) in vec3 a_pos;

out vec3 v_vertex_pos;

uniform mat4 u_model;

void main() 
{
    v_vertex_pos = a_pos;
    gl_Position = u_model * vec4(a_pos, 1.0);
}
