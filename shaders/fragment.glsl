precision highp float;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;
varying vec2 fragCoord;

vec2 getDistortedUv(vec2 uv, vec2 direction, float factor) {
    return uv - direction * factor * 0.5;
}

struct DistortedLens {
    vec2 uv_R;
    vec2 uv_G;
    vec2 uv_B;
    // 焦点的距离场，表示透镜内外的渐变区域
    float focusSdf;
    // 透镜的距离场，表示透镜的边界
    float sphereSdf;
    // 透镜内外的渐变区域，用于控制透镜效果的透明度
    float inside;
};

// 透镜扭曲
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
    float focusStrength = sphereRadius / 4000.0;
    float focusSdf = length(sphereCenter - p) - focusRadius;
    float sphereSdf = length(sphereCenter - p) - sphereRadius;
    float inside = smoothstep(0.0, 0.2, -sphereSdf / (sphereRadius * 0.3));
    
    float magnifierFactor = focusSdf / (sphereRadius - focusRadius);
    float mFactor = clamp(magnifierFactor * inside, 0.0, 1.0);
    mFactor = pow(mFactor, 3.0);

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
        sphereSdf,
        inside
    );
}

// 基础的UV坐标变换函数，用于实现缩放效果
vec2 zoomUV(vec2 uv, vec2 center, float zoom) {
    vec2 centeredUV = uv - center;  // 将UV坐标中心移到指定位置
    centeredUV *= zoom;             // 应用缩放
    return centeredUV + center;     // 移回原始位置
}

void main() {
    vec2 p = fragCoord * iResolution;
    vec2 vUv = fragCoord;
    
    // 透镜中心坐标
    vec2 sphereCenter = iMouse.xy;
    vec2 sphereCenterUv = sphereCenter / iResolution;
    // 透镜半径
    float sphereRadius = iResolution.y * 0.25;
    // 透镜聚焦因子，用于控制透镜效果的中心聚焦
    float focusFactor = 0.65;
    // 色差因子，用于控制透镜效果的色差
    float chromaticAberrationFactor = 0.15;
    // 缩放因子，用于控制透镜效果的缩放
    float zoom = 0.65;

    vec2 zoomedUv = zoomUV(vUv, sphereCenterUv, zoom);

    DistortedLens distortion = getLensDistortion(
        p, zoomedUv, sphereCenter, sphereRadius, focusFactor, chromaticAberrationFactor
    );
    
    vec4 baseTexture = texture2D(iChannel0, vUv);
    vec3 imageDistorted = vec3(
        texture2D(iChannel0, distortion.uv_R).r,
        texture2D(iChannel0, distortion.uv_G).g,
        texture2D(iChannel0, distortion.uv_B).b
    );

    vec3 result = mix(baseTexture.rgb, imageDistorted, distortion.inside);
    // 透镜效果的透明度
    float alpha = mix(0.0, 0.6, distortion.inside);
    
    gl_FragColor = vec4(result, alpha);
}
