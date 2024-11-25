#version 330 core

out vec4 frag_color;

in vec3 v_vertex_pos;

void main() 
{
    frag_color = vec4(v_vertex_pos, 1.0);
}