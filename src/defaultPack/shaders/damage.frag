#ifdef GL_ES
    precision lowp float;
#endif

varying vec2 v_texCoords;
varying vec4 v_color;
uniform sampler2D u_texture;

void main()
{
    float alpha = texture2D(u_texture, v_texCoords).a;
    gl_FragColor = vec4(v_color.rgb, v_color.a * alpha);
}
