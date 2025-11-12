#include <metal_stdlib>
using namespace metal;

/**
 * Stretch Video - Metal Shaders for Real-time Video Warping
 * 
 * These shaders perform mesh-based video warping using control points
 * for professional-quality real-time video transformation.
 */

// Vertex shader input
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

// Vertex shader output / Fragment shader input
struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

// Control point structure
struct ControlPoint {
    float2 position;
    float strength;
    float radius;
    int type; // 0 = stretch, 1 = anchor
};

// Uniforms structure
struct WarpUniforms {
    float2 videoSize;
    float globalStrength;
    int numControlPoints;
    float time;
    int interpolationType; // 0 = linear, 1 = smooth, 2 = elastic
};

/**
 * Applies warping transformation to a vertex position
 * 
 * @param position Original vertex position (normalized 0-1)
 * @param controlPoints Array of control points
 * @param uniforms Warp settings
 * @return Warped position
 */
float2 applyWarp(float2 position,
                 constant ControlPoint* controlPoints,
                 constant WarpUniforms& uniforms) {
    
    float2 warpedPosition = position;
    
    // Apply warping from each control point
    for (int i = 0; i < uniforms.numControlPoints && i < 16; i++) {
        ControlPoint point = controlPoints[i];
        
        // Calculate distance from vertex to control point
        float2 offset = position - point.position;
        float distance = length(offset);
        
        // Skip if outside influence radius
        if (distance >= point.radius || distance < 0.001) {
            continue;
        }
        
        // Calculate influence based on distance and interpolation type
        float influence = 1.0 - (distance / point.radius);
        
        switch (uniforms.interpolationType) {
            case 0: // Linear
                // influence already calculated
                break;
            case 1: // Smooth
                influence = smoothstep(0.0, 1.0, influence);
                break;
            case 2: // Elastic
                influence = influence * influence * (3.0 - 2.0 * influence);
                break;
        }
        
        // Apply warp based on point type
        if (point.type == 0) { // Stretch point
            float2 warpDirection = normalize(offset);
            float warpMagnitude = point.strength * influence * uniforms.globalStrength;
            
            // Stretch along the direction from control point
            warpedPosition += warpDirection * warpMagnitude * 0.1;
            
        } else { // Anchor point
            // Anchor points pull vertices towards them
            float anchorStrength = point.strength * influence * uniforms.globalStrength;
            warpedPosition -= offset * anchorStrength * 0.05;
        }
    }
    
    // Clamp to valid texture coordinates
    warpedPosition = clamp(warpedPosition, float2(0.0), float2(1.0));
    
    return warpedPosition;
}

/**
 * Vertex shader for mesh warping
 */
vertex VertexOut warpVertexShader(VertexIn in [[stage_in]],
                                  constant ControlPoint* controlPoints [[buffer(1)]],
                                  constant WarpUniforms& uniforms [[buffer(2)]]) {
    
    VertexOut out;
    
    // Apply warping to vertex position
    float2 warpedPos = applyWarp(in.position, controlPoints, uniforms);
    
    // Convert to clip space coordinates
    float2 clipSpace = (warpedPos * 2.0) - 1.0;
    clipSpace.y *= -1.0; // Flip Y for Metal coordinate system
    
    out.position = float4(clipSpace, 0.0, 1.0);
    out.texCoords = in.texCoords;
    
    return out;
}

/**
 * Fragment shader for video rendering
 */
fragment float4 warpFragmentShader(VertexOut in [[stage_in]],
                                   texture2d<float> videoTexture [[texture(0)]],
                                   constant WarpUniforms& uniforms [[buffer(0)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear,
                                    min_filter::linear,
                                    address::clamp_to_edge);
    
    // Sample the video texture
    float4 color = videoTexture.sample(textureSampler, in.texCoords);
    
    // Apply any additional effects based on settings
    // For example, quality reduction for real-time preview
    if (uniforms.time > 0.0) {
        // Add subtle animation or quality adjustments
        color.rgb = mix(color.rgb, floor(color.rgb * 64.0) / 64.0, 0.1);
    }
    
    return color;
}

/**
 * Compute shader for advanced warping effects
 * Used for more complex transformations that require multiple passes
 */
kernel void advancedWarpCompute(texture2d<float, access::read> inputTexture [[texture(0)]],
                               texture2d<float, access::write> outputTexture [[texture(1)]],
                               constant ControlPoint* controlPoints [[buffer(0)]],
                               constant WarpUniforms& uniforms [[buffer(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    
    // Check bounds
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    // Convert pixel coordinates to normalized coordinates
    float2 normalizedPos = float2(gid) / float2(outputTexture.get_width(), outputTexture.get_height());
    
    // Apply inverse warping to find source coordinates
    float2 sourcePos = applyWarp(normalizedPos, controlPoints, uniforms);
    
    // Convert back to pixel coordinates
    uint2 sourcePixel = uint2(sourcePos * float2(inputTexture.get_width(), inputTexture.get_height()));
    
    // Sample input texture with bounds checking
    float4 color = float4(0.0);
    if (sourcePixel.x < inputTexture.get_width() && sourcePixel.y < inputTexture.get_height()) {
        color = inputTexture.read(sourcePixel);
    }
    
    // Write to output texture
    outputTexture.write(color, gid);
}

/**
 * Utility functions for mesh generation
 */
struct MeshVertex {
    float2 position;
    float2 texCoords;
};

/**
 * Generates a mesh grid for warping
 */
constant int MESH_RESOLUTION = 32;

kernel void generateMesh(device MeshVertex* vertices [[buffer(0)]],
                        device uint* indices [[buffer(1)]],
                        constant WarpUniforms& uniforms [[buffer(2)]],
                        uint index [[thread_position_in_grid]]) {
    
    if (index >= (MESH_RESOLUTION + 1) * (MESH_RESOLUTION + 1)) {
        return;
    }
    
    int x = index % (MESH_RESOLUTION + 1);
    int y = index / (MESH_RESOLUTION + 1);
    
    float u = float(x) / float(MESH_RESOLUTION);
    float v = float(y) / float(MESH_RESOLUTION);
    
    vertices[index].position = float2(u, v);
    vertices[index].texCoords = float2(u, v);
    
    // Generate indices for triangles (done only for specific threads)
    if (x < MESH_RESOLUTION && y < MESH_RESOLUTION) {
        int quadIndex = y * MESH_RESOLUTION + x;
        int indexBase = quadIndex * 6;
        
        // Two triangles per quad
        int topLeft = y * (MESH_RESOLUTION + 1) + x;
        int topRight = topLeft + 1;
        int bottomLeft = (y + 1) * (MESH_RESOLUTION + 1) + x;
        int bottomRight = bottomLeft + 1;
        
        // First triangle
        indices[indexBase + 0] = topLeft;
        indices[indexBase + 1] = bottomLeft;
        indices[indexBase + 2] = topRight;
        
        // Second triangle
        indices[indexBase + 3] = topRight;
        indices[indexBase + 4] = bottomLeft;
        indices[indexBase + 5] = bottomRight;
    }
}