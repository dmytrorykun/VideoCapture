#version 150 core

in vec2 Texcoord;

out vec4 outColor;

uniform sampler2D tex;

void main()
{
    outColor = texture(tex, Texcoord);
    //outColor = vec4(1.0, 1.0, 0.5, 1.0);
}
