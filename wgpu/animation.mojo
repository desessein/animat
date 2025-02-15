from .renderer import Renderer
from math import *


struct AnimationBase:
    """
    Base implementation containing common GPU setup functions used across animations.
    These static functions handle the standard GPU resource management patterns.
    """

    @staticmethod
    fn create_bind_group_layout(
        device: wgpu.Device,
    ) -> ArcPointer[BindGroupLayout]:
        return ArcPointer(
            device.create_bind_group_layout(
                BindGroupLayoutDescriptor(
                    "bind group layout",
                    List[BindGroupLayoutEntry](
                        BindGroupLayoutEntry(
                            binding=0,
                            visibility=wgpu.ShaderStage.fragment
                            | wgpu.ShaderStage.vertex,
                            type=BufferBindingLayout(
                                type=wgpu.BufferBindingType.uniform,
                                has_dynamic_offset=False,
                                min_binding_size=sizeof[Float32](),
                            ),
                            count=0,
                        ),
                        BindGroupLayoutEntry(
                            binding=1,
                            visibility=wgpu.ShaderStage.fragment
                            | wgpu.ShaderStage.vertex,
                            type=BufferBindingLayout(
                                type=wgpu.BufferBindingType.uniform,
                                has_dynamic_offset=False,
                                min_binding_size=sizeof[Float32](),
                            ),
                            count=0,
                        ),
                    ),
                )
            )
        )

    @staticmethod
    fn create_vertex_attributes() -> List[VertexAttribute]:
        return List[VertexAttribute](
            VertexAttribute(
                format=VertexFormat.float32x3, offset=0, shader_location=0
            ),
            VertexAttribute(
                format=VertexFormat.float32x4,
                offset=sizeof[Vec3](),
                shader_location=1,
            ),
        )

    @staticmethod
    fn create_uniform_buffer(device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
        size = 512 + sizeof[Float32]()

        buffer = ArcPointer(
            device.create_buffer(
                BufferDescriptor(
                    "uniform buffer",
                    BufferUsage.uniform | BufferUsage.copy_dst,
                    size,
                    True,
                )
            )
        )
        uniform_dst = (
            buffer[].get_mapped_range(0, sizeof[Float32]()).bitcast[Float32]()
        )
        uniform_dst[0] = 0
        buffer[].unmap()
        return buffer

    @staticmethod
    fn create_bind_group(
        device: wgpu.Device,
        uniform_buffer: ArcPointer[Buffer],
        layout: ArcPointer[BindGroupLayout],
    ) -> wgpu.BindGroup:
        return device.create_bind_group(
            BindGroupDescriptor(
                "bind group",
                layout,
                List[BindGroupEntry](
                    BindGroupEntry(
                        0,
                        BufferBinding(uniform_buffer, 0, sizeof[Float32]()),
                    ),
                    BindGroupEntry(
                        1,
                        BufferBinding(uniform_buffer, 512, sizeof[Float32]()),
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

    fn create_uniform_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        ...

    fn create_bind_group(
        self,
        device: wgpu.Device,
        uniform_buffer: ArcPointer[Buffer],
        layout: ArcPointer[BindGroupLayout],
    ) -> wgpu.BindGroup:
        ...

    fn create_vertex_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        ...

    fn get_total_vertices(self) -> UInt32:
        ...


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

    fn create_shader_module(
        self, device: wgpu.Device
    ) raises -> wgpu.ShaderModule:
        return device.create_wgsl_shader_module(code=self.WAVE_SHADER_CODE)

    fn create_bind_group_layout(
        self, device: wgpu.Device
    ) -> ArcPointer[BindGroupLayout]:
        return AnimationBase.create_bind_group_layout(device)

    fn create_vertex_attributes(self) -> List[VertexAttribute]:
        return AnimationBase.create_vertex_attributes()

    fn create_uniform_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        return AnimationBase.create_uniform_buffer(device)

    fn create_bind_group(
        self,
        device: wgpu.Device,
        uniform_buffer: ArcPointer[Buffer],
        layout: ArcPointer[BindGroupLayout],
    ) -> wgpu.BindGroup:
        return AnimationBase.create_bind_group(device, uniform_buffer, layout)

    fn get_total_vertices(self) -> UInt32:
        return 250 * 6

    fn create_vertex_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        vertices = List[MyVertex]()

        # Create a line of points that will form the wave
        num_points = 250

        dot_size = Float32(0.02)

        for i in range(num_points):
            # Calculate x position from -1 to 1
            x = -1.0 + (2.0 * Float32(i) / num_points)

            # Add vertex with initial y=0
            # Triangle 1
            vertices.append(
                MyVertex(
                    Vec3(x - dot_size, -dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Bottom left
            vertices.append(
                MyVertex(
                    Vec3(x + dot_size, -dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Bottom right
            vertices.append(
                MyVertex(
                    Vec3(x + dot_size, dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Top right

            # Triangle 2
            vertices.append(
                MyVertex(
                    Vec3(x - dot_size, -dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Bottom left
            vertices.append(
                MyVertex(
                    Vec3(x + dot_size, dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Top right
            vertices.append(
                MyVertex(
                    Vec3(x - dot_size, dot_size, 0.0),
                    MyColor(0.0, 0.5, 1.0, 1.0),
                )
            )  # Top left

        # Create and fill buffer
        vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
        buffer = ArcPointer(
            device.create_buffer(
                BufferDescriptor(
                    "wave vertex buffer",
                    BufferUsage.vertex,
                    vertices_size_bytes,
                    True,
                )
            )
        )

        dst = (
            buffer[]
            .get_mapped_range(0, vertices_size_bytes)
            .bitcast[MyVertex]()
        )
        for i in range(len(vertices)):
            dst[i] = vertices[i]
        buffer[].unmap()

        return buffer


struct WaveInterferenceAnimation(Animation):
    """Creates a wave interference effect by combining two sine waves."""

    alias WAVE_INTERFERENCE_SHADER_CODE = """
        @group(0) @binding(0)
        var<uniform> time: f32;

        @group(0) @binding(1)
        var<uniform> mouse_pos: f32;

        struct VertexOutput {
            @builtin(position) position: vec4<f32>,
            @location(1) color: vec4<f32>,
        };

        @vertex
        fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
            var p = in_pos;
            
            let amplitude = 0.15 + mouse_pos * 0.01;

            // First wave moving left to right
            let wave1 = sin(p.x * 8.0 + time * 2.0) * 0.15 * amplitude;
            
            // Second wave moving right to left
            let wave2 = sin(-p.x * 8.0 + time * 2.0) * 0.15 * amplitude;
            
            if (p.y > 0.25) {
                p.y += wave1;
            } else if (p.y < -0.25) {
                p.y += wave1 + wave2;
            } else {
                p.y += wave2;
            }
            
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

    fn create_shader_module(
        self, device: wgpu.Device
    ) raises -> wgpu.ShaderModule:
        return device.create_wgsl_shader_module(
            code=self.WAVE_INTERFERENCE_SHADER_CODE
        )

    fn create_bind_group_layout(
        self, device: wgpu.Device
    ) -> ArcPointer[BindGroupLayout]:
        return AnimationBase.create_bind_group_layout(device)

    fn create_vertex_attributes(self) -> List[VertexAttribute]:
        return AnimationBase.create_vertex_attributes()

    fn create_uniform_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        return AnimationBase.create_uniform_buffer(device)

    fn create_bind_group(
        self,
        device: wgpu.Device,
        uniform_buffer: ArcPointer[Buffer],
        layout: ArcPointer[BindGroupLayout],
    ) -> wgpu.BindGroup:
        return AnimationBase.create_bind_group(device, uniform_buffer, layout)

    fn get_total_vertices(self) -> UInt32:
        return 100 * 100 * 6 * 3

    fn create_wave(self, y: Float32) -> List[MyVertex]:
        vertices = List[MyVertex]()

        grid_size = 100
        quad_size = Float32(0.02)

        for i in range(grid_size):
            for j in range(grid_size):
                x = -1.0 + Float32(i) * quad_size

                # Calculate color based on position
                color = MyColor(
                    Float32(i) / Float32(grid_size),
                    Float32(j) / Float32(grid_size),
                    0.8,
                    1.0,
                )

                # First triangle
                vertices.append(MyVertex(Vec3(x, y, 0.0), color))
                vertices.append(MyVertex(Vec3(x + quad_size, y, 0.0), color))
                vertices.append(
                    MyVertex(Vec3(x + quad_size, y + quad_size, 0.0), color)
                )

                # Second triangle
                vertices.append(MyVertex(Vec3(x, y, 0.0), color))
                vertices.append(
                    MyVertex(Vec3(x + quad_size, y + quad_size, 0.0), color)
                )
                vertices.append(MyVertex(Vec3(x, y + quad_size, 0.0), color))

        return vertices

    fn create_vertex_buffer(
        self, device: wgpu.Device
    ) -> ArcPointer[wgpu.Buffer]:
        wave_1 = self.create_wave(0.5)
        wave_2 = self.create_wave(0)
        wave_3 = self.create_wave(-0.5)

        vertices = wave_1 + wave_2 + wave_3

        vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
        buffer = ArcPointer(
            device.create_buffer(
                BufferDescriptor(
                    "wave interference vertex buffer",
                    BufferUsage.vertex,
                    vertices_size_bytes,
                    True,
                )
            )
        )

        dst = (
            buffer[]
            .get_mapped_range(0, vertices_size_bytes)
            .bitcast[MyVertex]()
        )
        for i in range(len(vertices)):
            dst[i] = vertices[i]
        buffer[].unmap()

        return buffer
