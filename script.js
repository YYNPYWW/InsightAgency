const container = document.querySelector('.container');
let program;
let mouseX = window.innerWidth / 2;
let mouseY = window.innerHeight / 2;
let targetMouseX = mouseX;
let targetMouseY = mouseY;
let texture = null;
let targetX = 0;
let targetY = 0;
let currentX = 0;
let currentY = 0;

const imgSources = Array.from(
    {length: 25},
    (_, i) => `./assets/img${i + 1}.jpg`
);

function getRandomImage() {
    return imgSources[Math.floor(Math.random() * imgSources.length)];
}

function createImageGrid() {
    for (let i = 0; i < 300; i++) {
        const wrapper = document.createElement('div');
        wrapper.className = 'img-wrapper';
        
        const img = document.createElement('img');
        img.src = getRandomImage();
        img.alt = 'Grid item';

        wrapper.appendChild(img);
        container.appendChild(wrapper);
    }
}

function updatePan (mouseX, mouseY) {
    const maxX = container.offsetWidth - window.innerWidth;
    const maxY = container.offsetHeight - window.innerHeight;

    targetX = -((mouseX / window.innerWidth) * maxX * 0.75);
    targetY = -((mouseY / window.innerHeight) * maxY * 0.75);
}

function animatePan() {
    const ease = 0.035;
    currentX += (targetX - currentX) * ease;
    currentY += (targetY - currentY) * ease;

    container.style.transform = `translate(${currentX}px, ${currentY}px)`;

    requestAnimationFrame(animatePan);
}

const canvas = document.querySelector('canvas');
const gl = canvas.getContext('webgl', {
    preserveDrawingBuffer: false,
    antialias: true,
    alpha: true,
});

function setupWebGL() {
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
}

function createShader(type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    
    if(!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error('An error occurred while compiling the shader:', gl.getShaderInfoLog(shader));
        gl.deleteShader(shader);
        return null;
    }

    return shader;
}

async function loadShaders() {
    try{
        const [vertexResponse, fragmentResponse] = await Promise.all([
            fetch('./shaders/vertex.glsl'),
            fetch('./shaders/fragment.glsl'),
        ]);

        const vertexSource = await vertexResponse.text();
        const fragmentSource = await fragmentResponse.text();

        return {vertexSource, fragmentSource};
    } catch (error) {
        console.error('An error occurred while loading shaders:', error);
        throw error;
    }
}

async function initWebGL() {
    setupWebGL();

    const {vertexSource, fragmentSource} = await loadShaders();
    const vertexShader = createShader(gl.VERTEX_SHADER, vertexSource);
    const fragmentShader = createShader(gl.FRAGMENT_SHADER, fragmentSource);

    program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    gl.useProgram(program);
}




function init() {
    program = new Program(container, {
        vertex: './shaders/vertex.glsl',
        fragment: './shaders/fragment.glsl'
    });
}

init();