#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uCenter;
uniform vec4 uSepiaColor;
out vec4 fragColor;

void main() {
    // Basic UV calculation
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / uSize;

    //. Get pixel distance from center
    float dist = length(uv - 0.5);

    float vignetteRadius = 0.4;
    float vignetteEdge = 0.6;
    float vignette = smoothstep(vignetteRadius, vignetteEdge, dist);
    vec4 sepiaColor = vec4(uSepiaColor.rgb * 0.9, 0.2);
    vec4 vignetteColor = vec4(0.0, 0.0, 0.0, vignette);
    // Combine the sepia color  with the vignette effect
    fragColor = sepiaColor * (1.0 - vignette) + vignetteColor;
}
