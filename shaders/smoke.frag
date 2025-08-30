#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uCameraOrbitAngle;
uniform vec3 uSpherePositions[20];
uniform float uSphereRadii[20];
uniform float uSphereOpacities[20];

out vec4 fragColor;

const int steps = 5;
const float eps = 1e-4;
const int levels = 10;
const float ditherScale = 2.5;
const vec3 sphereBaseColor = vec3(0.2);
const float lightIntensity = 0.25;

float bayer4(vec2 p) {
    ivec2 ip = ivec2(floor(mod(p, 4.0)));
    int idx = ip.x + ip.y * 4;
    const mat4 M = mat4(vec4(0, 8, 2, 10), vec4(12, 4, 14, 6), vec4(3, 11, 1, 9), vec4(15, 7, 13, 5));
    int val = 0;

    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            if(idx == i + j * 4) {
                val = int(M[i][j]);
            }
        }
    }
    return (float(val) + 0.5) / 16.0;
}

/// Tonemapping from Uncharted 2, by John Hable, Learn about it on: http://filmicworlds.com/blog/filmic-tonemapping-operators/ and https://mini.gmshaders.com/p/tonemaps

vec3 tonemapUncharted2(vec3 linearColor) {
    const float A = 0.15;
    const float B = 0.50;
    const float C = 0.10;
    const float D = 0.20;
    const float E = 0.02;
    const float F = 0.30;

    return ((linearColor * (A * linearColor + C * B) + D * E) / (linearColor * (A * linearColor + B) + D * F)) - E / F;
}

vec3 tonemapFilmic(vec3 hdrColor, float exposure) {
    vec3 exposed = hdrColor * exposure;
    vec3 mapped = tonemapUncharted2(exposed);
    vec3 white = tonemapUncharted2(vec3(11.2));
    mapped /= white;
    return pow(clamp(mapped, 0.0, 1.0), vec3(1.0 / 2.2));
}

vec3 raySphere(vec3 rayOrigin, vec3 rayDirection, vec3 sphereCenter, float sphereRadius) {
    vec3 originToCenter = rayOrigin - sphereCenter;
    float halfB = dot(originToCenter, rayDirection);
    float cTerm = dot(originToCenter, originToCenter) - sphereRadius * sphereRadius;
    float discriminant = halfB * halfB - cTerm;

    if(discriminant <= 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }

    float root = sqrt(discriminant);
    float t0 = -halfB - root;
    float t1 = -halfB + root;
    return vec3(t0, t1, 1.0);
}

float sphereDensity(vec3 samplePoint, vec3 sphereCenter, float sphereRadius, float edgeThickness) {
    float distanceFromCenter = length(samplePoint - sphereCenter);
    return smoothstep(sphereRadius, sphereRadius - edgeThickness, distanceFromCenter);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec4 backgroundColor = vec4(0.0);

    fragCoord.y += -43.0;

    vec2 screenUV = (fragCoord - 0.5 * uSize.xy) / uSize.y;

    float orbitAngleRad = radians(uCameraOrbitAngle);
    float orbitRadius = 31.5;
    vec3 cameraOrigin = vec3(orbitRadius * sin(orbitAngleRad), -20.0, orbitRadius * cos(orbitAngleRad));

    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    vec3 cameraForward = normalize(cameraTarget - cameraOrigin);
    vec3 cameraRight = normalize(cross(vec3(0.0, 1.0, 0.0), cameraForward));
    vec3 cameraUp = cross(cameraForward, cameraRight);
    float focalLength = 1.72;
    vec3 rayDirection = normalize(screenUV.x * cameraRight +
        screenUV.y * cameraUp +
        focalLength * cameraForward);

    float sphereEdgeThickness = 20.5;

    vec3 lightDirection = normalize(vec3(0, 1000.0, -300));

    float anySphereHit = 0.0;
    float tNear = 1e9;
    float tFar = -1e9;
    for(int i = 0; i < 20; ++i) {
        vec3 sphereCenter = uSpherePositions[i];
        float sphereRadius = uSphereRadii[i];
        vec3 hitData = raySphere(cameraOrigin, rayDirection, sphereCenter, sphereRadius);

        if(hitData.z > 0.5) {
            anySphereHit = 1.0;
            tNear = min(tNear, max(hitData.x, 0.0));
            tFar = max(tFar, hitData.y);
        }
    }

    if(anySphereHit == 0.0) {
        fragColor = backgroundColor;
        return;
    }

    if(tFar <= 0.0) {
        fragColor = backgroundColor;
        return;
    }

    tNear = max(tNear, 0.0);

    float absorptionCoefficient = 50.0;
    float emissionStrength = 4.0;
    float segmentLength = max(tFar - tNear, eps);
    float stepSize = segmentLength / float(steps);
    vec3 accumulatedColor = vec3(0.0);
    float transmittance = 1.0;

    float currentT = tNear;
    for(int stepIndex = 0; stepIndex < steps; ++stepIndex) {
        vec3 samplePoint = cameraOrigin + rayDirection * currentT;

        float densityAccum = 0.0;
        vec3 gradientApprox = vec3(0.0);
        for(int i = 0; i < 20; ++i) {
            vec3 sphereCenter = uSpherePositions[i];
            float sphereRadius = uSphereRadii[i];
            float sphereOpacity = uSphereOpacities[i];
            float seff = sphereEdgeThickness;
            seff = mix(1.0, 13.0, (sphereRadius - 0.5) / (2.5));

            float density = sphereDensity(samplePoint, sphereCenter, sphereRadius, seff) * sphereOpacity;
            densityAccum += density;

            if(density > eps)
                gradientApprox += (samplePoint - sphereCenter) * density;
        }

        float combinedDensity = clamp(densityAccum, 0.0, 1.0);

        if(combinedDensity > eps) {
            vec3 normalApprox = normalize(gradientApprox + 1e-2);
            float lambert = clamp(dot(normalApprox, lightDirection), 0.0, 1.0);
            lambert = lambert * lightIntensity + 0.1;
            vec3 sliceColor = sphereBaseColor * lambert;
            float absorb = 1.0 - exp(-absorptionCoefficient * combinedDensity * stepSize);
            accumulatedColor += transmittance * sliceColor * absorb * emissionStrength;
            transmittance *= (1.0 - absorb);
            if(transmittance < 0.01)
                break;
        }

        currentT += stepSize;
    }

    float exposure = 0.2;
    backgroundColor.rgb = tonemapFilmic(accumulatedColor, exposure);

    backgroundColor.a = clamp(1.0 - transmittance, 0.0, 1.0);

    fragColor = backgroundColor;

    float luminance = fragColor.r;
    float threshold = bayer4(fragCoord.xy / ditherScale);
    float scaled = clamp(luminance * float(levels), 0.0, float(levels) - 1e-6);
    float baseBin = floor(scaled);
    float fracPart = scaled - baseBin;
    float chosenBin = baseBin + (fracPart > threshold ? 1.0 : 0.0);
    chosenBin = clamp(chosenBin, 0.0, float(levels - 1));
    float outGray = chosenBin / float(levels - 1);

    fragColor.rgb = vec3(outGray);
}
