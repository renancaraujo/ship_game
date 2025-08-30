#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPixelSize;
uniform sampler2D tTexture;

out vec4 fragColor;

void main() {
    vec2 pos = FlutterFragCoord().xy / uPixelSize;
    vec2 uv = pos / uSize;
    vec4 texColor = texture(tTexture, uv);
    float grey = (texColor.r + texColor.g + texColor.b) / 3.0;
    texColor.rgb = vec3(grey);    
    fragColor = texColor;
}
