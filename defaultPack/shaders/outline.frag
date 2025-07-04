#ifdef GL_ES
    precision lowp float;
#endif

varying vec2 v_texCoords;
uniform sampler2D u_texture;
uniform vec2 u_textureSize;

void main()
{
    float alpha = texture2D(u_texture, v_texCoords).a;
    if (alpha < 0.5) {
      vec2 size = vec2(1.0, 1.0) / u_textureSize;

      vec4 tot = vec4(0.0, 0.0, 0.0, 0.0);
      tot += texture2D(u_texture, v_texCoords + vec2(    0.0,  size.y));
      tot += texture2D(u_texture, v_texCoords + vec2(    0.0, -size.y));
      tot += texture2D(u_texture, v_texCoords + vec2( size.x,     0.0));
      tot += texture2D(u_texture, v_texCoords + vec2(-size.x,     0.0));

      if (tot.a >= 0.1) {
        gl_FragColor = vec4(tot.rgb / tot.a, 1.0);
      } else {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0);
      }
    } else {
      gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0);
    }
}
