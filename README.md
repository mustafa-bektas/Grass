# GPU-Instanced Billboard Grass Renderer

![Demo](demo/grass_demo.gif)

An exploration of billboard grass rendering with GPU instancing. Handles millions of grass instances with no performance issues. This project was a good way to learn the power of GPU parallelization and how modern rendering techniques can push Unity's performance boundaries. 

## Technical Implementation

### Features
- **GPU Instancing with DrawMeshInstancedIndirect** - Renders 2+ million grass instances without CPU bottlenecks
- **Compute Shaders** - Parallel computation for grass positioning and properties on the GPU
- **Structured Buffers** - Efficient data transfer between CPU and GPU for grass transforms
- **Custom Shaders** - Billboarded grass with alpha cutout for optimal performance
- **Procedural Placement** - Simplex noise-based distribution for natural-looking grass fields
- **Terrain Integration** - Grass follows heightmap displacement, sampling terrain textures for accurate positioning
- **Dynamic Wind System** - Real-time wind simulation with directional control, affecting grass based on height and scale
- **Height Variation** - Procedural scaling creates realistic grass diversity with color gradients
- **LOD-friendly Billboarding** - Camera-facing sprites maintain visual quality at any viewing angle

### Shader Techniques
- Custom vertex displacement for wind animation
- Height-based color interpolation (green to yellow gradient)
- Optimized alpha testing for transparent grass textures
- Terrain displacement mapping with normal map support

### Performance Optimizations
- Single draw call for millions of instances
- Compute shader thread group optimization
- Minimal CPU-GPU synchronization
- Efficient buffer management with ComputeBufferType.IndirectArguments

