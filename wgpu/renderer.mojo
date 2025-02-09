from wgpu import *
from .types import *
from sys.info import sizeof
from .objects import RenderPassEncoder

struct Renderer:
    var device: wgpu.Device
    var pipeline: wgpu.RenderPipeline
    var surface: wgpu.Surface
    var vertex_buffer: ArcPointer[wgpu.Buffer]
    var uniform_bind_group: wgpu.BindGroup
    var uniform_buffer: ArcPointer[wgpu.Buffer]
    var queue: wgpu.Queue
    var adapter: wgpu.Adapter

    fn __init__(mut self, ref window: glfw.Window) raises:
        instance = wgpu.Instance()
        self.surface = instance.create_surface(window)
        self.adapter = instance.request_adapter_sync(self.surface)
        self.device = self.adapter.adapter_request_device()
        self.queue = self.device.get_queue()
        
        # Configure surface
        caps = self.surface.get_capabilities(self.adapter)
        surface_formats = caps.formats()
        format_0 = surface_formats[0]
        # Copy the first format value before caps is destroyed

        self.surface.configure(
            self.device,
            SurfaceConfiguration(
                width=640, height=480,
                usage=wgpu.TextureUsage.render_attachment,
                format=format_0,
                alpha_mode=wgpu.CompositeAlphaMode.auto,
                present_mode=wgpu.PresentMode.fifo,
                view_formats=List[TextureFormat](),
            )
        )        

        # Create shader and pipeline
        shader_module = self._create_shader_module(self.device)
        bind_group_layout = self._create_bind_group_layout(self.device)
        pipeline_layout = self._create_pipeline_layout(self.device, bind_group_layout)
        self.pipeline = self._create_pipeline(self.device, shader_module, pipeline_layout, format_0)

        # Create buffers and bind groups
        self.uniform_buffer = self._create_uniform_buffer(self.device)
        self.uniform_bind_group = self._create_bind_group(self.device, self.uniform_buffer, bind_group_layout)
        self.vertex_buffer = self._create_vertex_buffer(self.device) 

    @staticmethod
    fn _create_pipeline(
        device: wgpu.Device, 
        shader_module: wgpu.ShaderModule, 
        pipeline_layout: PipelineLayout,
        surface_format: TextureFormat
    ) -> wgpu.RenderPipeline:
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

        vertex_buffer_layout = VertexBufferLayout(
            array_stride=sizeof[MyVertex](),
            step_mode=VertexStepMode.vertex,
            attributes=Span(vertex_attributes),
        )

        desc = wgpu.RenderPipelineDescriptor(
            label="render pipeline",
            vertex=wgpu.VertexState(
                entry_point="vs_main",
                module=shader_module,
                buffers=List[VertexBufferLayout[__origin_of(vertex_attributes)]](
                    vertex_buffer_layout
                ),
            ),
            fragment=wgpu.FragmentState(
                module=shader_module,
                entry_point="fs_main",
                targets=List[wgpu.ColorTargetState](
                    wgpu.ColorTargetState(
                        blend=wgpu.BlendState(
                            color=wgpu.BlendComponent(
                                src_factor=wgpu.BlendFactor.src_alpha,
                                dst_factor=wgpu.BlendFactor.one_minus_src_alpha,
                                operation=wgpu.BlendOperation.add,
                            ),
                            alpha=wgpu.BlendComponent(
                                src_factor=wgpu.BlendFactor.zero,
                                dst_factor=wgpu.BlendFactor.one,
                                operation=wgpu.BlendOperation.add,
                            ),
                        ),
                        format=surface_format,
                        write_mask=wgpu.ColorWriteMask.all,
                    )
                ),
            ),
            primitive=wgpu.PrimitiveState(
                topology=wgpu.PrimitiveTopology.triangle_list,
            ),
            multisample=wgpu.MultisampleState(),
            layout=Pointer.address_of(pipeline_layout),
            depth_stencil=None,
        )
        return device.create_render_pipeline(descriptor=desc)


    @staticmethod
    fn _create_uniform_buffer(device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
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
    fn _create_bind_group(device: wgpu.Device, uniform_buffer: ArcPointer[Buffer],  layout: ArcPointer[BindGroupLayout]) -> wgpu.BindGroup:
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

    @staticmethod
    fn _create_vertex_buffer(device: wgpu.Device) -> ArcPointer[wgpu.Buffer]:
        vertices = List[MyVertex](
            MyVertex(Vec3(-0.5, -0.5, 0.0), MyColor(1, 0, 0, 1)),
            MyVertex(Vec3(0.5, -0.5, 0.0), MyColor(0, 1, 0, 1)),
            MyVertex(Vec3(0.0, 0.5, 0.0), MyColor(0, 0, 1, 1)),
        )
        vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
        buffer = ArcPointer(device.create_buffer(
            BufferDescriptor(
                "vertex buffer", 
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
    

    @staticmethod
    fn _create_bind_group_layout(device: wgpu.Device) -> ArcPointer[BindGroupLayout]:
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
    fn _create_pipeline_layout(device: wgpu.Device, bind_group_layout: ArcPointer[BindGroupLayout]) -> PipelineLayout:
        return device.create_pipeline_layout(
            PipelineLayoutDescriptor(
                "pipeline layout",
                List[ArcPointer[BindGroupLayout]](bind_group_layout),
            )
        )        

    @staticmethod
    fn _create_shader_module(device: wgpu.Device) raises -> wgpu.ShaderModule:
        shader_code = """
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

        return device.create_wgsl_shader_module(code=shader_code)

    fn render(self, ref u_time: Float32) raises -> Float32:
        with self.surface.get_current_texture() as surface_tex:
            if surface_tex.status != wgpu.SurfaceGetCurrentTextureStatus.success:
                raise Error("failed to get surface tex")
            
            target_view = surface_tex.texture[].create_view(
                format=surface_tex.texture[].get_format(),
                dimension=wgpu.TextureViewDimension.d2,
                base_mip_level=0,
                mip_level_count=1,
                base_array_layer=0,
                array_layer_count=1,
                aspect=wgpu.TextureAspect.all,
            )

            encoder = self.device.create_command_encoder()
            
            color_attachments = List[wgpu.RenderPassColorAttachment](
                wgpu.RenderPassColorAttachment(
                    view=target_view,
                    load_op=wgpu.LoadOp.clear,
                    store_op=wgpu.StoreOp.store,
                    clear_value=wgpu.Color(0.9, 0.1, 0.2, 1.0),
                )
            )

            self.queue.write_buffer(
                self.uniform_buffer,
                0,
                Span[UInt8, __origin_of(u_time)](
                    ptr=UnsafePointer.address_of(u_time).bitcast[UInt8](),
                    length=sizeof[Float32](),
                ),
            )

            rp = encoder.begin_render_pass(color_attachments=color_attachments)
            rp.set_pipeline(self.pipeline)
            rp.set_vertex_buffer(0, 0, self.vertex_buffer[].get_size(), self.vertex_buffer[])
            rp.set_bind_group(0, self.uniform_bind_group, List[UInt32]())
            rp.draw(3, 1, 0, 0)
            rp.end()

            command = encoder.finish()
            self.queue.submit(command)
            self.surface.present()
            
            return u_time + 0.05
            

struct BaseRenderer:
    var device: wgpu.Device
    var surface: wgpu.Surface
    var queue: wgpu.Queue
    var adapter: wgpu.Adapter
    var surface_format: TextureFormat

    fn __init__(mut self, ref window: glfw.Window) raises:
        instance = wgpu.Instance()
        self.surface = instance.create_surface(window)
        self.adapter = instance.request_adapter_sync(self.surface)
        self.device = self.adapter.adapter_request_device()
        self.queue = self.device.get_queue()
        
        # Configure surface
        caps = self.surface.get_capabilities(self.adapter)
        surface_formats = caps.formats()
        format_0 = surface_formats[0]
        self.surface_format = format_0
        self.configure_surface(600, 840)

    fn configure_surface(self, width: Int, height: Int) raises:
        self.surface.configure(
            self.device,
            SurfaceConfiguration(
                width=640, height=480,
                usage=wgpu.TextureUsage.render_attachment,
                format=self.surface_format,
                alpha_mode=wgpu.CompositeAlphaMode.auto,
                present_mode=wgpu.PresentMode.fifo,
                view_formats=List[TextureFormat](),
            )
        )  

    fn create_shader_module(self, code: String) raises -> wgpu.ShaderModule:
        """Create a shader module from WGSL code."""
        return self.device.create_wgsl_shader_module(code=code)

    fn create_buffer(self, label: StringLiteral, usage: BufferUsage, size: Int, 
                    mapped: Bool = False) -> ArcPointer[wgpu.Buffer]:
        """Create a GPU buffer with specified parameters."""
        return ArcPointer(
            self.device.create_buffer(
                BufferDescriptor(label, usage, size, mapped)
            )
        )        

    fn begin_render_pass(self, background_color: Color) raises -> (CommandEncoder, RenderPassEncoder):
        """Start a new render pass with specified background color."""
        with self.surface.get_current_texture() as surface_tex:
            if surface_tex.status != wgpu.SurfaceGetCurrentTextureStatus.success:
                raise Error("failed to get surface tex")
            
            target_view = surface_tex.texture[].create_view(
                format=self.surface_format,
                dimension=wgpu.TextureViewDimension.d2,
                base_mip_level=0,
                mip_level_count=1,
                base_array_layer=0,
                array_layer_count=1,
                aspect=wgpu.TextureAspect.all,
            )

            encoder = self.device.create_command_encoder()
            color_attachments = List[wgpu.RenderPassColorAttachment](
                wgpu.RenderPassColorAttachment(
                    view=target_view,
                    load_op=wgpu.LoadOp.clear,
                    store_op=wgpu.StoreOp.store,
                    clear_value=background_color,
                )
            )

            rp = encoder.begin_render_pass(color_attachments=color_attachments)
            
            return (encoder, rp)

    fn end_render_pass(self, encoder: wgpu.CommandEncoder):
        """End the render pass and present the frame."""
        command = encoder.finish()
        self.queue.submit(command)
        self.surface.present()            
