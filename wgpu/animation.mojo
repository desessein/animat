from .renderer import Renderer
from math import *

struct AnimationBase:
    """
    Base implementation containing common GPU setup functions used across animations.
    These static functions handle the standard GPU resource management patterns.
    """

    @staticmethod
    fn create_bind_group_layout(device: wgpu.Device) -> ArcPointer[BindGroupLayout]:
        return ArcPointer(
            device.create_bind_group_layout(
                BindGroupLayoutDescriptor(
                    "bind group layout",
                    List[BindGroupLayoutEntry](
                        BindGroupLayoutEntry(
                            binding=0,
                            visibility=wgpu.ShaderStage.fragment | wgpu.ShaderStage.vertex,
                            type=BufferBindingLayout(
                                type=wgpu.BufferBindingType.uniform,
                                has_dynamic_offset=False,
                                min_binding_size=sizeof[Float32](),
                            ),
                            count=0,
                        )
                    ),
                )
            )
        )

    @staticmethod
    fn create_vertex_attributes() -> List[VertexAttribute]:
        return List[VertexAttribute](
            VertexAttribute(
                format=VertexFormat.float32x3, 
                offset=0, 
                shader_location=0
            ),
            VertexAttribute(
                format=VertexFormat.float32x4,
                offset=sizeof[Vec3](),
                shader_location=1,
            ),
        )

    @staticmethod
    fn create_uniform_buffer(device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
        buffer = ArcPointer(
            device.create_buffer(
                BufferDescriptor(
                    "uniform buffer",
                    BufferUsage.uniform | BufferUsage.copy_dst,
                    sizeof[Float32](),
                    True,
                )
            )
        )
        uniform_dst = buffer[].get_mapped_range(0, sizeof[Float32]()).bitcast[Float32]()
        uniform_dst[0] = 0
        buffer[].unmap()
        return buffer

    @staticmethod
    fn create_bind_group(device: wgpu.Device, uniform_buffer: ArcPointer[Buffer], layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
        return device.create_bind_group(
            BindGroupDescriptor(
                "bind group",
                layout,
                List[BindGroupEntry](
                    BindGroupEntry(
                        0,
                        BufferBinding(uniform_buffer, 0, sizeof[Float32]()),
                    )
                ),
            )
        )



trait Animation:
      """
      Base trait for different animations.
      Implement this to create new types of animations.
    
      Functions:
      - __init__(): 
        Constructor for the animation. Sets up any initial state needed for the animation.
    
      - create_shader_module(device):
        Creates the GPU shader program using WGSL (WebGPU Shading Language).
        The shader defines both vertex processing (position, transformations) and 
        fragment processing (colors, textures). This is where the core visual 
        behavior of the animation is programmed.
    
      - create_bind_group_layout(device):
        Establishes the blueprint for how data will be passed to the shader.
        Defines what types of resources (buffers, textures) the shader expects,
        their bindings, and which shader stages can access them (vertex/fragment).
        Think of it as defining the "ports" where data can flow into the shader.
    
      - create_vertex_attributes():
        Specifies the format and organization of vertex data in memory.
        Returns a list of attributes (like position coordinates, color values)
        with their exact memory layout (offset, format) and shader locations.
        This tells the GPU how to interpret the raw vertex buffer data.
    
      - create_uniform_buffer(device):
        Creates a special buffer for data that stays constant for all vertices
        during a render pass (like time, transformation matrices).
        These values can be updated between frames to animate the content.
        The buffer is accessible by the shader through the bind group.
    
      - create_bind_group(device, uniform_buffer, layout):
        Connects actual GPU buffers to the slots defined in the bind group layout.
        Takes the uniform buffer and binds it to specific binding points that
        the shader can access. This is where the abstract layout becomes concrete
        with real data resources.
    
      - create_vertex_buffer(device):
        Allocates and fills a GPU buffer with the actual vertex data for rendering.
        Contains the raw geometry data (vertex positions, colors) in the format
        specified by vertex_attributes(). This is the actual shape data that
        will be transformed and rendered by the shader.
      """

      fn __init__(out self) raises:
          ...
        
      fn __copyinit__(mut self, copy: Self):
          ...

      fn create_shader_module(
          self, device: wgpu.Device
      ) raises -> wgpu.ShaderModule:
          ...

      fn create_bind_group_layout(
          self, device: wgpu.Device
      ) -> ArcPointer[BindGroupLayout]:
          ...

      fn create_vertex_attributes(self) -> List[VertexAttribute]:
          ...

      fn create_uniform_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
          ...

      fn create_bind_group(self, device: wgpu.Device, uniform_buffer: ArcPointer[Buffer],  layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
          ...

      fn create_vertex_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
          ...

      fn get_total_vertices(self) -> UInt32:
          ...


# struct TriangleAnimation(Animation):
#     alias TRIANGLE_SHADER_CODE = """
#             @group(0) @binding(0)
#             var<uniform> time: f32;

#             struct VertexOutput {
#                 @builtin(position) position: vec4<f32>,
#                 @location(1) color: vec4<f32>,
#             };

#             @vertex
#             fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
#                 var p = in_pos;
#                 return VertexOutput(vec4<f32>(p, 1.0), in_color);
#             }

#             @fragment
#             fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
#                 let t = cos(time * 0.1) * 0.5 + 0.5;
#                 let color = in_color + vec4<f32>(t, t, t, 1.0);
#                 return color;
#             }
#         """

#     fn __init__(out self) raises:
#         pass

#     fn create_shader_module(
#         self, device: wgpu.Device
#     ) raises -> wgpu.ShaderModule:
#         return device.create_wgsl_shader_module(code=self.TRIANGLE_SHADER_CODE)

#     fn create_bind_group_layout(
#         self, device: wgpu.Device
#     ) -> ArcPointer[BindGroupLayout]:
#         return ArcPointer(
#             device.create_bind_group_layout(
#                 BindGroupLayoutDescriptor(
#                     "bind group layout",
#                     List[BindGroupLayoutEntry](
#                         BindGroupLayoutEntry(
#                             binding=0,
#                             visibility=wgpu.ShaderStage.fragment
#                             | wgpu.ShaderStage.vertex,
#                             type=BufferBindingLayout(
#                                 type=wgpu.BufferBindingType.uniform,
#                                 has_dynamic_offset=False,
#                                 min_binding_size=sizeof[Float32](),
#                             ),
#                             count=0,
#                         )
#                     ),
#                 )
#             )
#         )

#     fn create_vertex_attributes(self) -> List[VertexAttribute]:
#         return List[VertexAttribute](
#             VertexAttribute(
#                 format=VertexFormat.float32x3, 
#                 offset=0, 
#                 shader_location=0
#             ),
#             VertexAttribute(
#                 format=VertexFormat.float32x4,
#                 offset=sizeof[Vec3](),
#             ),
#         )


#     fn create_uniform_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         buffer = ArcPointer(
#             device.create_buffer(
#                 BufferDescriptor(
#                     "uniform buffer",
#                     BufferUsage.uniform | BufferUsage.copy_dst,
#                     sizeof[Float32](),
#                     True,
#                 )
#             )
#         )
#         uniform_dst = buffer[].get_mapped_range(0, sizeof[Float32]()).bitcast[Float32]()
#         uniform_dst[0] = 0
#         buffer[].unmap()
#         return buffer

#     fn create_bind_group(self, device: wgpu.Device, uniform_buffer: ArcPointer[Buffer],  layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
#         return device.create_bind_group(
#             BindGroupDescriptor(
#                 "bind group",
#                 layout,
#                 List[BindGroupEntry](
#                     BindGroupEntry(
#                         0,
#                         BufferBinding(uniform_buffer, 0, sizeof[Float32]()),
#                     )
#                 ),
#             )
#         )        

#     fn create_vertex_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         vertices = List[MyVertex](
#             MyVertex(Vec3(-0.5, -0.5, 0.0), MyColor(1, 0, 0, 1)),
#             MyVertex(Vec3(0.5, -0.5, 0.0), MyColor(0, 1, 0, 1)),
#             MyVertex(Vec3(0.0, 0.5, 0.0), MyColor(0, 0, 1, 1)),
#         )
#         vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
#         buffer = ArcPointer(device.create_buffer(
#             BufferDescriptor(
#                 "vertex buffer", 
#                 BufferUsage.vertex, 
#                 vertices_size_bytes, 
#                 True
#             )
#         ))
#         dst = buffer[].get_mapped_range(0, vertices_size_bytes).bitcast[MyVertex]()
#         for i in range(len(vertices)):
#             dst[i] = vertices[i]
#         buffer[].unmap()
#         return buffer        

# struct SquareAnimation(Animation):
#     """
#     An animation that renders and animates a square using two triangles.
#     Demonstrates how to create more complex shapes from triangles.
#     """
#     # Define our shader code as a constant
#     alias SQUARE_SHADER_CODE = """
#         @group(0) @binding(0)
#         var<uniform> time: f32;

#         struct VertexOutput {
#             @builtin(position) position: vec4<f32>,
#             @location(1) color: vec4<f32>,
#         };

#         @vertex
#         fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
#             var p = in_pos;
            
#             // Create a rotation matrix
#             let angle = time * 0.5;  // Rotate at a moderate speed
#             let c = cos(angle);
#             let s = sin(angle);
#             let x = p.x * c - p.y * s;
#             let y = p.x * s + p.y * c;
#             p.x = x;
#             p.y = y;
            
#             // Add a gentle pulsing scale
#             let scale = 1.0 + sin(time * 2.0) * 0.2;
#             p.x *= scale;
#             p.y *= scale;
            
#             return VertexOutput(vec4<f32>(p, 1.0), in_color);
#         }

#         @fragment
#         fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
#             // Create a color animation that shifts between original colors and modified ones
#             let t = cos(time * 0.1) * 0.5 + 0.5;
#             let rainbow_color = vec4<f32>(
#                 sin(time) * 0.5 + 0.5,
#                 sin(time + 2.094) * 0.5 + 0.5,  // 2.094 = 2π/3
#                 sin(time + 4.189) * 0.5 + 0.5,  // 4.189 = 4π/3
#                 1.0
#             );
#             return mix(in_color, rainbow_color, t);
#         }
#     """

#     fn __init__(out self) raises:
#         pass

#     fn create_shader_module(
#         self, device: wgpu.Device
#     ) raises -> wgpu.ShaderModule:
#         # Create shader module using our square shader code
#         return device.create_wgsl_shader_module(code=self.SQUARE_SHADER_CODE)

#     # Reuse the bind group layout from TriangleAnimation
#     fn create_bind_group_layout(
#         self, device: wgpu.Device
#     ) -> ArcPointer[BindGroupLayout]:
#         return ArcPointer(
#             device.create_bind_group_layout(
#                 BindGroupLayoutDescriptor(
#                     "bind group layout",
#                     List[BindGroupLayoutEntry](
#                         BindGroupLayoutEntry(
#                             binding=0,
#                             visibility=wgpu.ShaderStage.fragment | wgpu.ShaderStage.vertex,
#                             type=BufferBindingLayout(
#                                 type=wgpu.BufferBindingType.uniform,
#                                 has_dynamic_offset=False,
#                                 min_binding_size=sizeof[Float32](),
#                             ),
#                             count=0,
#                         )
#                     ),
#                 )
#             )
#         )

#     # Reuse the vertex attributes from TriangleAnimation since we're still using position and color
#     fn create_vertex_attributes(self) -> List[VertexAttribute]:
#         return List[VertexAttribute](
#             VertexAttribute(
#                 format=VertexFormat.float32x3, 
#                 offset=0, 
#                 shader_location=0
#             ),
#             VertexAttribute(
#                 format=VertexFormat.float32x4,
#                 offset=sizeof[Vec3](),
#                 shader_location=1,
#             ),
#         )

#     # Reuse the uniform buffer creation from TriangleAnimation
#     fn create_uniform_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         buffer = ArcPointer(
#             device.create_buffer(
#                 BufferDescriptor(
#                     "uniform buffer",
#                     BufferUsage.uniform | BufferUsage.copy_dst,
#                     sizeof[Float32](),
#                     True,
#                 )
#             )
#         )
#         uniform_dst = buffer[].get_mapped_range(0, sizeof[Float32]()).bitcast[Float32]()
#         uniform_dst[0] = 0
#         buffer[].unmap()
#         return buffer

#     # Reuse the bind group creation from TriangleAnimation
#     fn create_bind_group(self, device: wgpu.Device, uniform_buffer: ArcPointer[Buffer], layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
#         return device.create_bind_group(
#             BindGroupDescriptor(
#                 "bind group",
#                 layout,
#                 List[BindGroupEntry](
#                     BindGroupEntry(
#                         0,
#                         BufferBinding(uniform_buffer, 0, sizeof[Float32]()),
#                     )
#                 ),
#             )
#         )

#     fn create_vertex_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         # Create a square using two triangles
#         # We need 6 vertices (2 triangles * 3 vertices each)
#         vertices = List[MyVertex](
#             # First triangle (bottom-left, bottom-right, top-right)
#             MyVertex(Vec3(-0.3, -0.3, 0.0), MyColor(1, 0, 0, 1)),    # Bottom-left red
#             MyVertex(Vec3(0.3, -0.3, 0.0), MyColor(0, 1, 0, 1)),     # Bottom-right green
#             MyVertex(Vec3(0.3, 0.3, 0.0), MyColor(0, 0, 1, 1)),      # Top-right blue
            
#             # # Second triangle (bottom-left, top-right, top-left)
#             MyVertex(Vec3(-0.3, -0.3, 0.0), MyColor(1, 0, 0, 1)),    # Bottom-left red
#             MyVertex(Vec3(0.3, 0.3, 0.0), MyColor(0, 0, 1, 1)),      # Top-right blue
#             MyVertex(Vec3(-0.3, 0.3, 0.0), MyColor(1, 1, 0, 1)),     # Top-left yellow
#         )
        
#         # Create and initialize the vertex buffer
#         vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
#         buffer = ArcPointer(device.create_buffer(
#             BufferDescriptor(
#                 "square vertex buffer", 
#                 BufferUsage.vertex, 
#                 vertices_size_bytes, 
#                 True
#             )
#         ))
        
#         # Copy our vertex data to the buffer
#         dst = buffer[].get_mapped_range(0, vertices_size_bytes).bitcast[MyVertex]()
#         for i in range(len(vertices)):
#             dst[i] = vertices[i]
#         buffer[].unmap()
        
#         return buffer

# struct KaleidoscopeAnimation(Animation):
#     """Creates a simple kaleidoscope effect."""
#     alias KALEIDOSCOPE_SHADER_CODE = """
#         @group(0) @binding(0)
#         var<uniform> time: f32;

#         struct VertexOutput {
#             @builtin(position) position: vec4<f32>,
#             @location(1) color: vec4<f32>,
#         };

#         @vertex
#         fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
#             var p = in_pos;
            
#             // Create multiple rotated copies
#             let angle = atan2(p.y, p.x);
#             let distance = sqrt(p.x * p.x + p.y * p.y);
#             let num_segments = 6.0;
#             let segment_angle = floor(angle * num_segments / 6.28318) * 6.28318 / num_segments;
            
#             let c = cos(segment_angle + time);
#             let s = sin(segment_angle + time);
#             p.x = distance * c;
#             p.y = distance * s;
            
#             return VertexOutput(vec4<f32>(p, 1.0), in_color);
#         }

#         @fragment
#         fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
#             return in_color * vec4<f32>(
#                 sin(time) * 0.5 + 0.5,
#                 cos(time) * 0.5 + 0.5,
#                 sin(time * 0.5) * 0.5 + 0.5,
#                 1.0
#             );
#         }
#     """

#     fn __init__(out self) raises:
#         pass

#     fn create_shader_module(
#         self, device: wgpu.Device
#     ) raises -> wgpu.ShaderModule:
#         # Create shader module using our square shader code
#         return device.create_wgsl_shader_module(code=self.KALEIDOSCOPE_SHADER_CODE )

#     # Reuse the bind group layout from TriangleAnimation
#     fn create_bind_group_layout(
#         self, device: wgpu.Device
#     ) -> ArcPointer[BindGroupLayout]:
#         return ArcPointer(
#             device.create_bind_group_layout(
#                 BindGroupLayoutDescriptor(
#                     "bind group layout",
#                     List[BindGroupLayoutEntry](
#                         BindGroupLayoutEntry(
#                             binding=0,
#                             visibility=wgpu.ShaderStage.fragment | wgpu.ShaderStage.vertex,
#                             type=BufferBindingLayout(
#                                 type=wgpu.BufferBindingType.uniform,
#                                 has_dynamic_offset=False,
#                                 min_binding_size=sizeof[Float32](),
#                             ),
#                             count=0,
#                         )
#                     ),
#                 )
#             )
#         )

#     # Reuse the vertex attributes from TriangleAnimation since we're still using position and color
#     fn create_vertex_attributes(self) -> List[VertexAttribute]:
#         return List[VertexAttribute](
#             VertexAttribute(
#                 format=VertexFormat.float32x3, 
#                 offset=0, 
#                 shader_location=0
#             ),
#             VertexAttribute(
#                 format=VertexFormat.float32x4,
#                 offset=sizeof[Vec3](),
#                 shader_location=1,
#             ),
#         )

#     # Reuse the uniform buffer creation from TriangleAnimation
#     fn create_uniform_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         buffer = ArcPointer(
#             device.create_buffer(
#                 BufferDescriptor(
#                     "uniform buffer",
#                     BufferUsage.uniform | BufferUsage.copy_dst,
#                     sizeof[Float32](),
#                     True,
#                 )
#             )
#         )
#         uniform_dst = buffer[].get_mapped_range(0, sizeof[Float32]()).bitcast[Float32]()
#         uniform_dst[0] = 0
#         buffer[].unmap()
#         return buffer

#     # Reuse the bind group creation from TriangleAnimation
#     fn create_bind_group(self, device: wgpu.Device, uniform_buffer: ArcPointer[Buffer], layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
#         return device.create_bind_group(
#             BindGroupDescriptor(
#                 "bind group",
#                 layout,
#                 List[BindGroupEntry](
#                     BindGroupEntry(
#                         0,
#                         BufferBinding(uniform_buffer, 0, sizeof[Float32]()),
#                     )
#                 ),
#             )
#         )

#     fn create_vertex_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
#         # Create a triangular pattern that will be replicated by the shader
#         vertices = List[MyVertex]()
        
#         # Create a series of triangles
#         num_triangles = 8
#         for i in range(num_triangles):
#             angle = Float32(i) * 2.0 * 3.14159 / Float32(num_triangles)
#             next_angle = Float32(i + 1) * 2.0 * 3.14159 / Float32(num_triangles)
            
#             vertices.append(MyVertex(Vec3(0, 0, 0), MyColor(1, 0, 0, 1)))
#             vertices.append(MyVertex(
#                 Vec3(cos(angle) * 0.5, sin(angle) * 0.5, 0),
#                 MyColor(0, 1, 0, 1)
#             ))
#             vertices.append(MyVertex(
#                 Vec3(cos(next_angle) * 0.5, sin(next_angle) * 0.5, 0),
#                 MyColor(0, 0, 1, 1)
#             ))
        
#         # Create and fill buffer
#         vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
#         buffer = ArcPointer(device.create_buffer(
#             BufferDescriptor(
#                 "kaleidoscope vertex buffer", 
#                 BufferUsage.vertex, 
#                 vertices_size_bytes, 
#                 True
#             )
#         ))
        
#         dst = buffer[].get_mapped_range(0, vertices_size_bytes).bitcast[MyVertex]()
#         for i in range(len(vertices)):
#             dst[i] = vertices[i]
#         buffer[].unmap()
        
#         return buffer
        
struct WaveAnimation(Animation):
    """Creates a simple animated wave effect using sine functions."""
    
    alias WAVE_SHADER_CODE = """
        @group(0) @binding(0)
        var<uniform> time: f32;

        struct VertexOutput {
            @builtin(position) position: vec4<f32>,
            @location(1) color: vec4<f32>,
        };

        @vertex
        fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
            var p = in_pos;
            
            // Create wave motion
            p.y += sin(p.x * 5.0 + time) * 0.2;
            
            return VertexOutput(vec4<f32>(p, 1.0), in_color);
        }

        @fragment
        fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
            // Animate color based on position and time
            return in_color * vec4<f32>(
                sin(time * 0.5) * 0.5 + 0.5,
                cos(time * 0.3) * 0.5 + 0.5,
                sin(time * 0.7) * 0.5 + 0.5,
                1.0
            );
        }
    """

    fn __init__(out self) raises:
        pass

    fn __copyinit__(mut self, copy: Self):
        pass

    fn create_shader_module(self, device: wgpu.Device) raises -> wgpu.ShaderModule:
        return device.create_wgsl_shader_module(code=self.WAVE_SHADER_CODE)

    fn create_bind_group_layout(self, device: wgpu.Device) -> ArcPointer[BindGroupLayout]:
        return AnimationBase.create_bind_group_layout(device)

    fn create_vertex_attributes(self) -> List[VertexAttribute]:
        return AnimationBase.create_vertex_attributes()

    fn create_uniform_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
        return AnimationBase.create_uniform_buffer(device)

    fn create_bind_group(self, device: wgpu.Device, uniform_buffer: ArcPointer[Buffer], layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
        return AnimationBase.create_bind_group(device, uniform_buffer, layout)
    
    fn get_total_vertices(self) -> UInt32:
        return 250 * 6

    fn create_vertex_buffer(self, device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
        vertices = List[MyVertex]()

        # Create a line of points that will form the wave
        num_points = 250

        dot_size = Float32(0.02)

        for i in range(num_points):
            # Calculate x position from -1 to 1
            x = -1.0 + (2.0 * Float32(i) / num_points)
            
            # Add vertex with initial y=0
            # Triangle 1
            vertices.append(MyVertex(Vec3(x - dot_size, -dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))  # Bottom left
            vertices.append(MyVertex(Vec3(x + dot_size, -dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))  # Bottom right
            vertices.append(MyVertex(Vec3(x + dot_size, dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))   # Top right

            # Triangle 2
            vertices.append(MyVertex(Vec3(x - dot_size, -dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))  # Bottom left
            vertices.append(MyVertex(Vec3(x + dot_size, dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))   # Top right
            vertices.append(MyVertex(Vec3(x - dot_size, dot_size, 0.0), MyColor(0.0, 0.5, 1.0, 1.0)))   # Top left
            
        # Create and fill buffer
        vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
        buffer = ArcPointer(device.create_buffer(
            BufferDescriptor(
                "wave vertex buffer", 
                BufferUsage.vertex, 
                vertices_size_bytes, 
                True
            )
        ))
        
        dst = buffer[].get_mapped_range(0, vertices_size_bytes).bitcast[MyVertex]()
        for i in range(len(vertices)):
            dst[i] = vertices[i]
        buffer[].unmap()
        
        return buffer

