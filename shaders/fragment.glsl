precision highp float;

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;

varying vec2 vUv;
varying vec2 vPosition;

// 获取变形后的UV坐标
vec2 getDistortedUv(vec2 uv, vec2 direction, float factor) {
    return uv - direction * factor;
}

// 定义变形镜头结构体
struct DistortedLens {
    vec2 uv_R;
    vec2 uv_G;
    vec2 uv_B;
    float focusSdf;
    float speherSdf;
    float inside;
};

// 获取镜头变形效果
DistortedLens getLensDistortion(
    vec2 p,
    vec2 uv,
    vec2 sphereCenter,
    float sphereRadius,
    float focusFactor,
    float chromaticAberrationFactor
) {
    vec2 distortionDirection = normalize(p - sphereCenter);

    float focusRadius = sphereRadius * focusFactor;
    float focusStrength = sphereRadius / 2000.0;

    float focusSdf = length(sphereCenter - p) - focusRadius;
    float speherSdf = length(sphereCenter - p) - sphereRadius;
    float inside = clamp(-speherSdf / fwidth(speherSdf), 0., 1.);
    
    float magnifierFactor = focusSdf / (sphereRadius - focusRadius);
    
    float mFactor = clamp(magnifierFactor * inside, 0., 1.);
    mFactor = pow(mFactor, 4.0);

    vec3 distortionFactors = vec3(
        mFactor * focusStrength * (1.0 + chromaticAberrationFactor),
        mFactor * focusStrength,
        mFactor * focusStrength * (1.0 - chromaticAberrationFactor)
    );
    
    vec2 uv_R = getDistortedUv(uv, distortionDirection, distortionFactors.r);
    vec2 uv_G = getDistortedUv(uv, distortionDirection, distortionFactors.g);
    vec2 uv_B = getDistortedUv(uv, distortionDirection, distortionFactors.b);

    return DistortedLens(
        uv_R,
        uv_G,
        uv_B,
        focusSdf,
        speherSdf,
        inside
    );
}

// UV缩放函数
vec2 zoomUV(vec2 uv, vec2 center, float zoom) {
    float zoomFactor = 1.0 / zoom;
    vec2 centeredUV = uv - center;
    centeredUV *= zoomFactor;
    return centeredUV + center;
}

void main() {
    vec2 p = gl_FragCoord.xy;
    vec3 result = vec3(1.0);
    
    vec2 textureSize = iResolution.xy;
    vec2 sphereCenter = iMouse.xy == vec2(0., 0.) ? iResolution.xy / 2. : iMouse.xy;
    vec2 spehereCenterUv = sphereCenter / textureSize;

    float sphereRadius = iResolution.y * 0.35;
    float focusFactor = 0.7;
    float chromaticAberrationFactor = 0.2;

    float zoom = 1.5;
    vec2 zoomedUv = zoomUV(vUv, spehereCenterUv, zoom);

    DistortedLens distortion = getLensDistortion(
        p, zoomedUv, sphereCenter, sphereRadius, focusFactor, chromaticAberrationFactor
    );
    
    float imageDistorted_R = texture2D(iChannel0, distortion.uv_R).r;
    float imageDistorted_G = texture2D(iChannel0, distortion.uv_G).g;
    float imageDistorted_B = texture2D(iChannel0, distortion.uv_B).b;

    vec3 imageDistorted = vec3(
        imageDistorted_R,
        imageDistorted_G,
        imageDistorted_B
    );
    
    vec3 image = texture2D(iChannel0, vUv).rgb;
    image = mix(image, imageDistorted, distortion.inside);
    result = vec3(image);
    
    gl_FragColor = vec4(result, 1.0);
}
