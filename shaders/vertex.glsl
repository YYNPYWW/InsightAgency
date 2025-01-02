attribute vec4 position;
attribute vec2 uv;

varying vec2 vUv;
varying vec2 vPosition;

void main() {
    vUv = uv;
    vPosition = position.xy;
    gl_Position = position;
}
