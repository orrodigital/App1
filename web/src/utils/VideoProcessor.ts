import { ControlPoint, WarpSettings } from '../types';

/**
 * VideoProcessor handles real-time video warping and rendering using WebGL
 * 
 * Key features:
 * - Hardware-accelerated video processing
 * - Real-time mesh warping based on control points
 * - Preserve video quality with minimal compression
 * - Smooth interpolation between frames
 */
export default class VideoProcessor {
  private canvas: HTMLCanvasElement;
  private gl: WebGL2RenderingContext;
  private video: HTMLVideoElement | null = null;
  private shaderProgram: WebGLProgram | null = null;
  private texture: WebGLTexture | null = null;
  private vertexBuffer: WebGLBuffer | null = null;
  private indexBuffer: WebGLBuffer | null = null;
  private controlPoints: ControlPoint[] = [];
  private warpSettings: WarpSettings;
  private meshResolution: number = 32; // Higher = more detailed warping
  private isInitialized: boolean = false;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const gl = canvas.getContext('webgl2');
    
    if (!gl) {
      throw new Error('WebGL 2.0 is not supported');
    }
    
    this.gl = gl;
    this.warpSettings = {
      strength: 1.0,
      interpolation: 'smooth',
      preserveAspectRatio: false,
      realTimePreview: true,
      quality: 'preview'
    };

    this.initializeWebGL();
  }

  private initializeWebGL(): void {
    const { gl } = this;

    // Vertex shader for mesh transformation
    const vertexShaderSource = `#version 300 es
      in vec2 a_position;
      in vec2 a_texCoord;
      out vec2 v_texCoord;
      
      uniform vec2 u_resolution;
      uniform float u_time;
      
      // Control point uniforms (max 16 points for performance)
      uniform vec2 u_controlPoints[16];
      uniform float u_controlStrengths[16];
      uniform float u_controlRadii[16];
      uniform int u_numControlPoints;
      uniform float u_globalStrength;
      
      vec2 applyWarp(vec2 position) {
        vec2 warpedPos = position;
        
        for (int i = 0; i < u_numControlPoints && i < 16; i++) {
          vec2 controlPoint = u_controlPoints[i];
          float strength = u_controlStrengths[i];
          float radius = u_controlRadii[i];
          
          vec2 offset = position - controlPoint;
          float distance = length(offset);
          
          if (distance < radius && distance > 0.0) {
            // Smooth falloff based on distance
            float influence = 1.0 - (distance / radius);
            influence = smoothstep(0.0, 1.0, influence);
            
            // Apply stretch transformation
            vec2 warpDirection = normalize(offset);
            float warpAmount = strength * influence * u_globalStrength;
            
            warpedPos += warpDirection * warpAmount * 0.1;
          }
        }
        
        return warpedPos;
      }
      
      void main() {
        vec2 normalizedPos = a_position / u_resolution;
        vec2 warpedPos = applyWarp(normalizedPos);
        
        // Convert back to clip space
        vec2 clipSpace = (warpedPos * u_resolution / u_resolution) * 2.0 - 1.0;
        clipSpace.y *= -1.0;
        
        gl_Position = vec4(clipSpace, 0.0, 1.0);
        v_texCoord = a_texCoord;
      }
    `;

    // Fragment shader for video rendering
    const fragmentShaderSource = `#version 300 es
      precision mediump float;
      
      in vec2 v_texCoord;
      out vec4 outColor;
      
      uniform sampler2D u_texture;
      uniform float u_time;
      uniform float u_quality;
      
      void main() {
        // Sample the video texture
        vec4 color = texture(u_texture, v_texCoord);
        
        // Apply quality adjustments
        if (u_quality < 1.0) {
          // Reduce quality for real-time preview
          color.rgb = floor(color.rgb * 32.0) / 32.0;
        }
        
        outColor = color;
      }
    `;

    // Compile shaders
    const vertexShader = this.compileShader(vertexShaderSource, gl.VERTEX_SHADER);
    const fragmentShader = this.compileShader(fragmentShaderSource, gl.FRAGMENT_SHADER);

    // Create shader program
    this.shaderProgram = gl.createProgram();
    if (!this.shaderProgram) {
      throw new Error('Failed to create shader program');
    }

    gl.attachShader(this.shaderProgram, vertexShader);
    gl.attachShader(this.shaderProgram, fragmentShader);
    gl.linkProgram(this.shaderProgram);

    if (!gl.getProgramParameter(this.shaderProgram, gl.LINK_STATUS)) {
      const error = gl.getProgramInfoLog(this.shaderProgram);
      throw new Error(`Shader program linking failed: ${error}`);
    }

    // Create vertex buffer for mesh
    this.createMesh();
    
    // Create texture for video
    this.texture = gl.createTexture();
    
    this.isInitialized = true;
  }

  private compileShader(source: string, type: number): WebGLShader {
    const { gl } = this;
    const shader = gl.createShader(type);
    
    if (!shader) {
      throw new Error('Failed to create shader');
    }

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const error = gl.getShaderInfoLog(shader);
      gl.deleteShader(shader);
      throw new Error(`Shader compilation failed: ${error}`);
    }

    return shader;
  }

  private createMesh(): void {
    const { gl } = this;
    
    // Create a grid mesh for warping
    const vertices: number[] = [];
    const indices: number[] = [];
    const texCoords: number[] = [];

    // Generate vertices and texture coordinates
    for (let y = 0; y <= this.meshResolution; y++) {
      for (let x = 0; x <= this.meshResolution; x++) {
        const u = x / this.meshResolution;
        const v = y / this.meshResolution;
        
        // Position (normalized 0-1)
        vertices.push(u, v);
        
        // Texture coordinates
        texCoords.push(u, v);
      }
    }

    // Generate indices for triangles
    for (let y = 0; y < this.meshResolution; y++) {
      for (let x = 0; x < this.meshResolution; x++) {
        const topLeft = y * (this.meshResolution + 1) + x;
        const topRight = topLeft + 1;
        const bottomLeft = (y + 1) * (this.meshResolution + 1) + x;
        const bottomRight = bottomLeft + 1;

        // Two triangles per quad
        indices.push(topLeft, bottomLeft, topRight);
        indices.push(topRight, bottomLeft, bottomRight);
      }
    }

    // Create and bind vertex buffer
    this.vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([...vertices, ...texCoords]), gl.STATIC_DRAW);

    // Create and bind index buffer
    this.indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
  }

  async loadVideo(videoUrl: string): Promise<void> {
    if (this.video) {
      this.video.pause();
      this.video.src = '';
    }

    this.video = document.createElement('video');
    this.video.crossOrigin = 'anonymous';
    this.video.muted = true;
    this.video.loop = true;

    return new Promise((resolve, reject) => {
      if (!this.video) return reject(new Error('Video element not created'));
      
      this.video.onloadeddata = () => {
        this.setupVideoTexture();
        resolve();
      };
      
      this.video.onerror = () => {
        reject(new Error('Failed to load video'));
      };
      
      this.video.src = videoUrl;
      this.video.load();
    });
  }

  private setupVideoTexture(): void {
    if (!this.video || !this.texture) return;
    
    const { gl } = this;
    
    gl.bindTexture(gl.TEXTURE_2D, this.texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  }

  updateWarpPoints(points: ControlPoint[]): void {
    this.controlPoints = points;
  }

  updateSettings(settings: WarpSettings): void {
    this.warpSettings = settings;
  }

  render(currentTime?: number): void {
    if (!this.isInitialized || !this.video || !this.shaderProgram) return;

    const { gl } = this;

    // Update video texture
    if (this.video.readyState >= this.video.HAVE_CURRENT_DATA) {
      gl.bindTexture(gl.TEXTURE_2D, this.texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, this.video);
    }

    // Clear canvas
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    // Use shader program
    gl.useProgram(this.shaderProgram);

    // Set up vertex attributes
    const positionLocation = gl.getAttribLocation(this.shaderProgram, 'a_position');
    const texCoordLocation = gl.getAttribLocation(this.shaderProgram, 'a_texCoord');

    gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);
    
    // Position attribute
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
    
    // Texture coordinate attribute
    gl.enableVertexAttribArray(texCoordLocation);
    const vertexCount = (this.meshResolution + 1) * (this.meshResolution + 1);
    gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, vertexCount * 2 * 4);

    // Set uniforms
    const resolutionLocation = gl.getUniformLocation(this.shaderProgram, 'u_resolution');
    gl.uniform2f(resolutionLocation, this.canvas.width, this.canvas.height);

    const timeLocation = gl.getUniformLocation(this.shaderProgram, 'u_time');
    gl.uniform1f(timeLocation, currentTime || 0);

    const globalStrengthLocation = gl.getUniformLocation(this.shaderProgram, 'u_globalStrength');
    gl.uniform1f(globalStrengthLocation, this.warpSettings.strength);

    const qualityLocation = gl.getUniformLocation(this.shaderProgram, 'u_quality');
    const qualityValue = this.warpSettings.quality === 'final' ? 1.0 : 
                        this.warpSettings.quality === 'preview' ? 0.8 : 0.5;
    gl.uniform1f(qualityLocation, qualityValue);

    // Set control point uniforms
    const numPointsLocation = gl.getUniformLocation(this.shaderProgram, 'u_numControlPoints');
    gl.uniform1i(numPointsLocation, Math.min(this.controlPoints.length, 16));

    const pointsLocation = gl.getUniformLocation(this.shaderProgram, 'u_controlPoints');
    const strengthsLocation = gl.getUniformLocation(this.shaderProgram, 'u_controlStrengths');
    const radiiLocation = gl.getUniformLocation(this.shaderProgram, 'u_controlRadii');

    const points = new Float32Array(32); // 16 points * 2 coordinates
    const strengths = new Float32Array(16);
    const radii = new Float32Array(16);

    this.controlPoints.slice(0, 16).forEach((point, i) => {
      points[i * 2] = point.x;
      points[i * 2 + 1] = point.y;
      strengths[i] = point.strength;
      radii[i] = point.radius;
    });

    gl.uniform2fv(pointsLocation, points);
    gl.uniform1fv(strengthsLocation, strengths);
    gl.uniform1fv(radiiLocation, radii);

    // Bind texture
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this.texture);
    const textureLocation = gl.getUniformLocation(this.shaderProgram, 'u_texture');
    gl.uniform1i(textureLocation, 0);

    // Draw the mesh
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
    const indexCount = this.meshResolution * this.meshResolution * 6;
    gl.drawElements(gl.TRIANGLES, indexCount, gl.UNSIGNED_SHORT, 0);
  }

  /**
   * Export the warped video with full quality
   * This would integrate with a backend service for production use
   */
  async exportVideo(
    format: 'mp4' | 'mov' | 'webm' = 'mp4',
    quality: 'high' | 'medium' | 'low' = 'high'
  ): Promise<Blob> {
    if (!this.video) {
      throw new Error('No video loaded');
    }

    // For production, this would:
    // 1. Create an offscreen canvas with higher resolution
    // 2. Process each frame with the warp transformations
    // 3. Use WebCodecs API or send to backend for encoding
    // 4. Return the processed video blob
    
    console.log('Export configuration:', {
      format,
      quality,
      controlPoints: this.controlPoints,
      warpSettings: this.warpSettings,
      videoInfo: {
        duration: this.video.duration,
        width: this.video.videoWidth,
        height: this.video.videoHeight
      }
    });

    // Placeholder implementation - in production this would be much more complex
    throw new Error('Video export not yet implemented - requires backend processing');
  }

  destroy(): void {
    const { gl } = this;
    
    if (this.video) {
      this.video.pause();
      this.video.src = '';
      this.video = null;
    }

    if (this.texture) {
      gl.deleteTexture(this.texture);
      this.texture = null;
    }

    if (this.vertexBuffer) {
      gl.deleteBuffer(this.vertexBuffer);
      this.vertexBuffer = null;
    }

    if (this.indexBuffer) {
      gl.deleteBuffer(this.indexBuffer);
      this.indexBuffer = null;
    }

    if (this.shaderProgram) {
      gl.deleteProgram(this.shaderProgram);
      this.shaderProgram = null;
    }

    this.isInitialized = false;
  }
}