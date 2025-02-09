from .renderer import BaseRenderer
from .bind_group_helper import *
from .buffer_creator import *
from .pipeline_builder import *

trait Animation:
    """
    Base trait for different animations.
    Implement this to create new types of animations.
    """
    fn __init__(out self: Self, renderer: BaseRenderer) raises:
        ...
    fn update(mut self, dt: Float32, renderer: BaseRenderer) raises:
        ...
    fn render(self, renderer: BaseRenderer) raises:
        ...


struct TriangleAnimation(Animation):
    alias TRIANGLE_SHADER_CODE = """
            @group(0) @binding(0)
            var<uniform> time: f32;

            struct VertexOutput {
                @builtin(position) position: vec4<f32>,
                @location(1) color: vec4<f32>,
            };

            @vertex
            fn vs_main(@location(0) in_pos: vec3<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
                var p = in_pos;
                return VertexOutput(vec4<f32>(p, 1.0), in_color);
            }

            @fragment
            fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
                let t = cos(time * 0.1) * 0.5 + 0.5;
                let color = in_color + vec4<f32>(t, t, t, 1.0);
                return color;
            }
        """

    var pipeline: wgpu.RenderPipeline
    var vertex_buffer: ArcPointer[wgpu.Buffer]
    var uniform_buffer: ArcPointer[wgpu.Buffer]
    var uniform_bind_group: wgpu.BindGroup
    var time: Float32

    fn __init__(out self, renderer: BaseRenderer) raises:
        self.time = 0.0

        pipeline_builder = PipelineBuilder(renderer.device, renderer.surface_format)

       # Create vertex buffer using generic helper
        vertices = List[MyVertex](
            MyVertex(Vec3(-0.5, -0.5, 0.0), MyColor(1, 0, 0, 1)),
            MyVertex(Vec3(0.5, -0.5, 0.0), MyColor(0, 1, 0, 1)),
            MyVertex(Vec3(0.0, 0.5, 0.0), MyColor(0, 0, 1, 1)),
        )
        self.vertex_buffer = BufferCreator._create_vertex_buffer(renderer.device, vertices)

        # Create uniform buffer using generic helper
        size = sizeof[Float32]()
        self.uniform_buffer = BufferCreator._create_uniform_buffer(renderer.device, size)
        bind_group_layout = BindGroupHelper._create_bind_group_layout(renderer.device, size)
        self.uniform_bind_group = BindGroupHelper._create_bind_group(renderer.device, self.uniform_buffer, bind_group_layout , size)


        vertex_attributes = List[VertexAttribute](
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

        vertex_layout = VertexBufferLayout(
            array_stride=sizeof[MyVertex](),
            step_mode=VertexStepMode.vertex,
            attributes=Span(vertex_attributes),
        )

        self.pipeline = pipeline_builder.create_shader_pipeline(
            shader_code=self.TRIANGLE_SHADER_CODE,  # Your shader code here
            vertex_layout=vertex_layout,
            bind_group_layouts=List[ArcPointer[BindGroupLayout]](bind_group_layout)
        )


    fn update(mut self, dt: Float32, renderer: BaseRenderer) raises:
        self.time += dt
        # Update uniform buffer with new time
        renderer.queue.write_buffer(
            self.uniform_buffer,
            0,
            Span[UInt8, __origin_of(self.time)](
                ptr=UnsafePointer.address_of(self.time).bitcast[UInt8](),
                length=sizeof[Float32](),
            ),
        )

    fn render(self, renderer: BaseRenderer) raises:
        # Get render pass
        (encoder, rp) = renderer.begin_render_pass(Color(0.1, 0.2, 0.3, 1.0))

        renderer.queue.write_buffer(
            self.uniform_buffer,
            0,
            Span[UInt8, __origin_of(self.time)](
                ptr=UnsafePointer.address_of(self.time).bitcast[UInt8](),
                length=sizeof[Float32](),
            ),
        )
        
        # Draw triangle
        rp.set_pipeline(self.pipeline)
        rp.set_vertex_buffer(0, 0, self.vertex_buffer[].get_size(), self.vertex_buffer[])
        rp.set_bind_group(0, self.uniform_bind_group, List[UInt32]())
        rp.draw(3, 1, 0, 0)
        rp.end()
        
        # End render pass
        renderer.end_render_pass(encoder)

        command = encoder.finish()
        renderer.queue.submit(command)
        renderer.surface.present()

