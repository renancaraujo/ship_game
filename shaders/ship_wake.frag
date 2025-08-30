#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uPixelSize;

uniform sampler2D tTexture;

out vec4 fragColor;

const float PI = 3.14159265359;

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// psrdnoise (c) Stefan Gustavson and Ian McEwan,
// ver. 2021-12-02, published under the MIT license:
// https://github.com/stegu/psrdnoise/
float psrdnoise(vec2 x, vec2 period, float alpha, out vec2 gradient) {
    vec2 uv = vec2(x.x + x.y * 0.5, x.y);
    vec2 i0 = floor(uv), f0 = fract(uv);
    float cmp = step(f0.y, f0.x);
    vec2 o1 = vec2(cmp, 1.0 - cmp);
    vec2 i1 = i0 + o1, i2 = i0 + 1.0;
    vec2 v0 = vec2(i0.x - i0.y * 0.5, i0.y);
    vec2 v1 = vec2(v0.x + o1.x - o1.y * 0.5, v0.y + o1.y);
    vec2 v2 = vec2(v0.x + 0.5, v0.y + 1.0);
    vec2 x0 = x - v0, x1 = x - v1, x2 = x - v2;
    vec3 iu, iv, xw, yw;
    if(any(greaterThan(period, vec2(0.0)))) {
        xw = vec3(v0.x, v1.x, v2.x);
        yw = vec3(v0.y, v1.y, v2.y);
        if(period.x > 0.0)
            xw = mod(vec3(v0.x, v1.x, v2.x), period.x);
        if(period.y > 0.0)
            yw = mod(vec3(v0.y, v1.y, v2.y), period.y);
        iu = floor(xw + 0.5 * yw + 0.5);
        iv = floor(yw + 0.5);
    } else {
        iu = vec3(i0.x, i1.x, i2.x);
        iv = vec3(i0.y, i1.y, i2.y);
    }
    vec3 hash = mod(iu, 289.0);
    hash = mod((hash * 51.0 + 2.0) * hash + iv, 289.0);
    hash = mod((hash * 34.0 + 10.0) * hash, 289.0);
    vec3 psi = hash * 0.07482 + alpha;
    vec3 gx = cos(psi);
    vec3 gy = sin(psi);
    vec2 g0 = vec2(gx.x, gy.x);
    vec2 g1 = vec2(gx.y, gy.y);
    vec2 g2 = vec2(gx.z, gy.z);
    vec3 w = 0.8 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
    w = max(w, 0.0);
    vec3 w2 = w * w;
    vec3 w4 = w2 * w2;
    vec3 gdotx = vec3(dot(g0, x0), dot(g1, x1), dot(g2, x2));
    float n = dot(w4, gdotx);
    vec3 w3 = w2 * w;
    vec3 dw = -8.0 * w3 * gdotx;
    vec2 dn0 = w4.x * g0 + dw.x * x0;
    vec2 dn1 = w4.y * g1 + dw.y * x1;
    vec2 dn2 = w4.z * g2 + dw.z * x2;
    gradient = 10.9 * (dn0 + dn1 + dn2);
    return 10.9 * n;
}

vec2 domainWarp(vec2 p, float t, float k) {
    vec2 q = p * 0.6 + 0.10 * t;
    vec2 w = vec2(vnoise(q), vnoise(q + 10000.0));
    return p + k * w;
}

float streakFoam(vec2 uv, vec2 flowDir, float t) {
    vec2 T = normalize(flowDir);
    vec2 N = vec2(-T.y, T.x);

    mat2 A = mat2(6.0 * T + 1.9 * N, 0.25 * T + 22.0 * N);

    vec2 P = A * uv;

    P += T * (t * 0.05);           // << movement along the wake
    P = domainWarp(P, t, 0.10);

    float sum = 0.0, amp = 0.8, frq = 2;
    for(int i = 0; i < 20; i++) {
        vec2 g;
        float n = abs(psrdnoise(P * frq, vec2(0.0), t * 6.0, g));
        sum += amp * n;
        frq *= 2.0;
        amp *= 0.55;
    }

    float hp = smoothstep(0.55, 0.85, sum) - smoothstep(0.85, 1.00, sum);
    hp += 0.08 * (vnoise(uv * 18.0 - vec2(0.0, 0.5 * t)) - 0.5);
    return clamp(hp * 1.6, 0.0, 1.0);
}

vec2 wakeEmitter(vec2 uv) {
    vec4 tex = texture(tTexture, uv);

    vec2 res = vec2(0.0);
    res.x = smoothstep(0.10, 0.85, tex.g);
    res.y = smoothstep(0.00, 0.95, tex.r);
    return res;
}

void main() {
    vec2 frag = FlutterFragCoord().xy / uPixelSize;
    vec2 uv = frag / uSize;

    float t = -uTime * 0.4;

    vec2 flowDir = vec2(1.0, 0.0);

    // emitter from texture, with soft edges
    vec2 emtieres = wakeEmitter(uv);
    vec4 tex = texture(tTexture, uv);  // r: inner, g: outer

    float emitg = emtieres.x;          // outer (gentle) foam
    float emitr = emtieres.y;      // inner (strong) foam

    float speedg = 0.12;
    float speedr = 0.10;                  // speed of wake travel

    // structured foam (streaks) advected over time
    float filg = streakFoam(uv * 4.0 - vec2(0, uTime * speedg), flowDir, t);
    float filr = streakFoam(uv * 4.0 - vec2(0, uTime * speedr), flowDir, t);

    float foamg = emitg * (0.05 * emitg + filg);
    float foamr = emitr * (emitr + filr);

    // clean onset and cap
    foamg = smoothstep(0.30, 0.95, foamg);
    foamr = smoothstep(0.30, 0.95, foamr);

    float foam = max(foamg, foamr);

    // final: only foam, no texture color rendered
    vec3 foamColor = vec3(0.93, 0.98, 1.0);             // cold white foam

    fragColor = vec4(foamColor * foam, foam);

    float fade = smoothstep(0.0, 0.5, uv.y);
    fragColor.rgb *= (1.0 - fade);
}