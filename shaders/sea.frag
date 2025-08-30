#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uRotation;

out vec4 fragColor;

const int NUM_STEPS = 1;
const float PI = 3.141592;
const float EPSILON = 1e-3;
#define EPSILON_NRM (0.08 / uSize.x)
const int ITER_GEOMETRY = 2;
const int ITER_FRAGMENT = 2;
const float SEA_HEIGHT = 1.9;
const float SEA_CHOPPY = 1.3;
const float SEA_SPEED = 0.81;
const float SEA_FREQ = 0.32;
const vec3 SEA_BASE = vec3(0.005);
#define SEA_TIME (1.0 + uTime * SEA_SPEED)
const mat2 octave_m = mat2(1.2, 1.2, -1.2, 1.6);

/*
 * "Seascape" by Alexander Alekseev aka TDM - 2014
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Changes made to the original shader:
 * - Changed base colors to look black and white
 * - remove camera moviment and synced to a uniform to define the angle and speed of the camera
 * - Remove a lot of perspective look more octonogal-ish
 * - Increased water highlights
 * - Adapted to Flutters style fo shader
 */
mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x), cos(ang.x));
    vec2 a2 = vec2(sin(ang.y), cos(ang.y));
    vec2 a3 = vec2(sin(ang.z), cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x);
    m[1] = vec3(-a2.y * a1.x, a1.y * a2.y, a2.x);
    m[2] = vec3(a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y);
    return m;
}

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float diffuse(vec3 n, vec3 l, float p) {
    return pow(dot(n, l) * 0.0 + 0.6, p);
}

float specular(vec3 n, vec3 l, vec3 e, float s) {
    float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

float sea_octave(vec2 uv, float choppy) {
    uv += noise(uv);
    vec2 wv = 1.0 - abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float map(vec3 p) {
    float freq = SEA_FREQ;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz;
    uv.x *= 0.75;

    float d, h = 0.0;
    for(int i = 0; i < ITER_GEOMETRY; i++) {
        d = sea_octave((uv + SEA_TIME) * freq, choppy);
        d += sea_octave((uv - SEA_TIME) * freq, choppy);
        uv *= octave_m;
        freq *= 1.9;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

float map_detailed(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz;
    uv.x *= 0.3;
    uv.y *= 0.3;

    float d, h = 0.0;
    for(int i = 0; i < ITER_FRAGMENT; i++) {
        d = sea_octave((uv + SEA_TIME) * freq, choppy);
        d += sea_octave((uv - SEA_TIME) * freq, choppy);
        h += d * amp;
        uv *= octave_m;
        freq *= 1.9;
        amp *= 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {
    float fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
    fresnel = min(fresnel * fresnel * fresnel, .5);

    vec3 reflected = vec3(.0);
    vec3 refracted = SEA_BASE + diffuse(n, l, 50.0);

    vec3 color = mix(refracted, reflected, fresnel);

    color += specular(n, l, eye, 1000.0 * inversesqrt(dot(dist, dist * 0.01)));

    return color;
}

vec3 getNormal(vec3 p, float eps) {
    vec3 n;
    n.y = map_detailed(p);
    n.x = map_detailed(vec3(p.x + eps, p.y, p.z)) - n.y;
    n.z = map_detailed(vec3(p.x, p.y, p.z + eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

float heightMapTracing(vec3 ori, vec3 dir, out vec3 p) {
    float tm = 0.0;
    float tx = 1000.0;

    float hx = map(ori + dir * tx);
    if(hx > 0.0) {
        p = ori + dir * tx;
        return tx;
    }
    float hm = map(ori);
    for(int i = 0; i < NUM_STEPS; i++) {
        float tmid = mix(tm, tx, hm / (hm - hx));
        p = ori + dir * tmid;
        float hmid = map(p);
        if(hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
        if(abs(hmid) < EPSILON)
            break;
    }
    return mix(tm, tx, hm / (hm - hx));
}

vec3 getPixel(in vec2 coord, float time) {
    vec2 uv = coord / uSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= uSize.x / uSize.y;

    float r = 1480.0;

    float t = uRotation;

    vec3 ang = vec3(0.0, 0.83, -t);
    vec3 ori = vec3(r * sin(t), 178.5, time + r * cos(t));
    vec3 dir = normalize(vec3(uv.xy, -2.0));
    dir.z += length(uv) * 0.01;
    dir = normalize(dir) * fromEuler(ang);

    vec3 p;
    heightMapTracing(ori, dir, p);
    vec3 dist = p - ori + vec3(0.0, 30.5, 0.0);
    vec3 n = getNormal(p, dot(dist, dist) * EPSILON_NRM);
    vec3 light = normalize(vec3(0.0, 1000.5, -1500)) * 0.96;

    vec3 color = mix(vec3(1), getSeaColor(p, n, light, dir, dist), pow(smoothstep(0.0, -0.02, dir.y), 0.2));

    float brightness = dot(color, vec3(0.299, 0.587, 0.114));
    float highlightMask = pow(brightness, 2.5);
    color = color + color * highlightMask * 2.5;

    return color;
}

void main() {
    float time = -uTime * 14.0;
    vec2 fragCoord = FlutterFragCoord().xy * vec2(1.0, -1.0) + vec2(0.0, uSize.y);
    vec3 color = getPixel(fragCoord, time);
    fragColor = vec4(pow(color, vec3(0.85)), 1.0);

}
